import csv
import io
import openpyxl
from django.shortcuts import render, redirect
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required, user_passes_test
from django.db import transaction
from django.views.decorators.http import require_http_methods
from django.utils.decorators import method_decorator
from django.contrib import messages
from django.core.paginator import Paginator
from django.db.models import Q
from api.models import Product, ActivityLog


# ── Guard: only superusers / staff may access upload portal ──────────────────
def is_admin(user):
    return user.is_authenticated and (user.is_superuser or user.is_staff)


# ── Login ─────────────────────────────────────────────────────────────────────
@require_http_methods(["GET", "POST"])
def portal_login(request):
    if request.user.is_authenticated and is_admin(request.user):
        return redirect('upload:dashboard')

    error = None
    if request.method == "POST":
        username = request.POST.get("username", "").strip()
        password = request.POST.get("password", "")
        user = authenticate(request, username=username, password=password)
        if user is None:
            error = "Invalid username or password."
        elif not (user.is_superuser or user.is_staff):
            error = "You don't have admin access to this portal."
        else:
            login(request, user)
            messages.success(request, f"Successfully signed in as {user.username}.")
            return redirect('upload:dashboard')

    return render(request, "upload/login.html", {"error": error})


# ── Logout ────────────────────────────────────────────────────────────────────
def portal_logout(request):
    logout(request)
    messages.success(request, "You have been securely signed out.")
    return redirect('upload:login')


# ── Dashboard / upload page ───────────────────────────────────────────────────
@login_required(login_url='upload:login')
@user_passes_test(is_admin, login_url='upload:login')
def portal_dashboard(request):
    """
    GET  – render the upload form with current product stats.
    POST – process the uploaded Excel file (xlsx only) and show results.
    """
    local_count = Product.objects.count()
    if local_count > 0:
        total_products = local_count
    else:
        from api.mssql_client import get_total_products_count
        total_products = get_total_products_count()

    recent_logs = ActivityLog.objects.filter(
        activity_type='inventory_audit'
    ).order_by('-created_at')[:20]

    context = {
        "total_products": total_products,
        "recent_logs": recent_logs,
        "user": request.user,
    }

    if request.method != "POST":
        return render(request, "upload/dashboard.html", context)

    # ── Handle upload ─────────────────────────────────────────────────────
    uploaded_file = request.FILES.get("file")
    mode = request.POST.get("mode", "upsert")
    if mode not in ["upsert", "replace"]:
        mode = "upsert"

    if not uploaded_file:
        context["upload_error"] = "No file selected. Please choose an Excel (.xlsx) file."
        return render(request, "upload/dashboard.html", context)

    filename = uploaded_file.name.lower()
    if not filename.endswith(".xlsx"):
        context["upload_error"] = "Only Excel (.xlsx) files are accepted."
        return render(request, "upload/dashboard.html", context)

    # Parse Excel -----------------------------------------------------------
    file_bytes = uploaded_file.read()
    try:
        wb = openpyxl.load_workbook(io.BytesIO(file_bytes), read_only=True, data_only=True)
        sheet = wb.active
        excel_rows = list(sheet.iter_rows(values_only=True))
    except Exception as exc:
        context["upload_error"] = f"Failed to parse Excel file: {exc}"
        return render(request, "upload/dashboard.html", context)

    if not excel_rows:
        context["upload_error"] = "The Excel sheet is empty."
        return render(request, "upload/dashboard.html", context)

    # Headers ---------------------------------------------------------------
    raw_headers = excel_rows[0]
    headers = []
    for h in raw_headers:
        headers.append(str(h).strip().lower() if h is not None else "")

    rows_data = []
    for row in excel_rows[1:]:
        if row and any(cell is not None and str(cell).strip() != "" for cell in row):
            rows_data.append([str(cell) if cell is not None else "" for cell in row])

    # Column index detection ------------------------------------------------
    code_idx = name_idx = label_idx = price1_idx = price2_idx = price3_idx = None

    for idx, h in enumerate(headers):
        if h in ["product code", "product_code", "code", "pluno", "item code", "item_code", "id"]:
            code_idx = idx
        elif h in ["product name", "product_name", "name", "itemname", "description", "item_name", "item name"]:
            name_idx = idx
        elif h in ["price label", "price_label", "label", "description_price", "unit name", "unit_name", "unit"]:
            label_idx = idx
        elif h in ["price a", "price_a", "price 1", "price_1", "unitprice", "unit_price", "price", "a"]:
            price1_idx = idx
        elif h in ["price b", "price_b", "price 2", "price_2", "priceamt", "price_amt", "b"]:
            price2_idx = idx
        elif h in ["price c", "price_c", "price 3", "price_3", "changeamount", "change_amount", "c"]:
            price3_idx = idx

    if code_idx is None:
        context["upload_error"] = 'Column "product code" or "code" not found in the file.'
        return render(request, "upload/dashboard.html", context)
    if name_idx is None:
        context["upload_error"] = 'Column "product name" or "name" not found in the file.'
        return render(request, "upload/dashboard.html", context)

    def parse_price(val):
        if not val:
            return 0.0
        clean = str(val).replace("$", "").replace("₹", "").replace(",", "").strip()
        try:
            return float(clean)
        except ValueError:
            return 0.0

    created_count = updated_count = skipped_count = 0
    total_rows = len(rows_data)

    try:
        with transaction.atomic():
            if mode == "replace":
                Product.objects.all().delete()

            existing = {p.product_code: p for p in Product.objects.all()}
            to_create = []
            seen = set()

            for row in rows_data:
                while len(row) < len(headers):
                    row.append("")

                code = row[code_idx].strip()
                name = row[name_idx].strip()

                if not code or not name:
                    skipped_count += 1
                    continue
                if code in seen:
                    skipped_count += 1
                    continue
                seen.add(code)

                label = row[label_idx].strip() if label_idx is not None else ""
                p1 = parse_price(row[price1_idx]) if price1_idx is not None else 0.0
                p2 = parse_price(row[price2_idx]) if price2_idx is not None else 0.0
                p3 = parse_price(row[price3_idx]) if price3_idx is not None else 0.0

                if code in existing:
                    prod = existing[code]
                    prod.name = name
                    prod.price_label = label
                    prod.price_1 = p1
                    prod.price_2 = p2
                    prod.price_3 = p3
                    prod.save()
                    updated_count += 1
                else:
                    to_create.append(Product(
                        product_code=code,
                        name=name,
                        price_label=label,
                        price_1=p1,
                        price_2=p2,
                        price_3=p3,
                    ))
                    created_count += 1

            if to_create:
                Product.objects.bulk_create(to_create)

            ActivityLog.objects.create(
                activity_type="inventory_audit",
                title="Products Uploaded via Web Portal",
                subtitle=(
                    f"Mode: {mode.upper()} — "
                    f"Created {created_count}, Updated {updated_count}, "
                    f"Skipped {skipped_count}. "
                    f"Uploaded by {request.user.username}."
                ),
            )

    except Exception as exc:
        context["upload_error"] = f"Database error: {exc}"
        return render(request, "upload/dashboard.html", context)

    # Refresh stats after upload
    context["total_products"] = Product.objects.count()
    context["recent_logs"] = ActivityLog.objects.filter(
        activity_type="inventory_audit"
    ).order_by("-created_at")[:20]

    context["upload_result"] = {
        "mode": mode,
        "original_filename": uploaded_file.name,
        "total_rows": total_rows,
        "created": created_count,
        "updated": updated_count,
        "skipped": skipped_count,
        "total_in_db": context["total_products"],
    }
    return render(request, "upload/dashboard.html", context)


# ── Products list ──────────────────────────────────────────────────────────────
@login_required(login_url='upload:login')
@user_passes_test(is_admin, login_url='upload:login')
def portal_products(request):
    query = request.GET.get('q', '').strip()
    sort  = request.GET.get('sort', 'product_code')
    order = request.GET.get('order', 'asc')

    allowed_sorts = ['product_code', 'name', 'price_label', 'price_1', 'price_2', 'price_3']
    if sort not in allowed_sorts:
        sort = 'product_code'
    if order not in ['asc', 'desc']:
        order = 'asc'

    local_count = Product.objects.count()
    
    if local_count > 0:
        total_products = local_count
        qs = Product.objects.all()
        if query:
            qs = qs.filter(
                Q(product_code__icontains=query) |
                Q(name__icontains=query) |
                Q(price_label__icontains=query)
            )

        order_prefix = '-' if order == 'desc' else ''
        qs = qs.order_by(f'{order_prefix}{sort}')
    else:
        from api.mssql_client import search_products, get_total_products_count
        total_products = get_total_products_count()
        raw_results = search_products(query if query else None)
        
        # Convert MSSQL list of dicts to standard dicts matching our template
        qs_list = []
        for row in raw_results:
            qs_list.append({
                'product_code': str(row.get('product code', '')),
                'name': str(row.get('product name', '')),
                'price_label': str(row.get('price label', '')),
                'price_1': float(row.get('price a') or 0.0),
                'price_2': float(row.get('price b') or 0.0),
                'price_3': float(row.get('price c') or 0.0),
            })
            
        # In-memory sorting for list of dicts
        reverse = (order == 'desc')
        try:
            qs = sorted(qs_list, key=lambda x: str(x.get(sort, '')).lower(), reverse=reverse)
        except Exception:
            qs = qs_list

    paginator = Paginator(qs, 50)
    page_number = request.GET.get('page', 1)
    page_obj = paginator.get_page(page_number)

    context = {
        'user': request.user,
        'page_obj': page_obj,
        'query': query,
        'sort': sort,
        'order': order,
        'total_count': paginator.count,
        'total_products': total_products,
    }
    return render(request, 'upload/products.html', context)
