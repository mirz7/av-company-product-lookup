import urllib.request
import os

os.makedirs('stitch_screens', exist_ok=True)

downloads = [
    # Splash Screen
    {"url": "https://lh3.googleusercontent.com/aida/ADBb0ugTjkC8fkANizDP9ssMkaEsTsvLRlTx16FEXJSXe_cuI8GLxn3s2mO_mGLMHmyyBLL-zvOmzHTLNklW2Hijbe3w9Crmy1akvUHwAXcSR-k_iQNyMz9Q3w4ULHn7PhMLykj5zADh1mxjHbZhIFTNvw4TdMruTeq7gpQCNSyly4nViAUGZGo0RWhLO7nf6O6_s63Qj4RA_6YX9bQSr-bSoLnjfrqqoctZYC16f4aEa4N1E1h4DNJ9HtVn59E", "path": "stitch_screens/splash_screen.png"},
    {"url": "https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ7Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpaCiVodG1sX2U1ZWZiMjJjYmI0YTQzMjY5MDZkZmNjZTlhOTRkNDY2EgsSBxDV5eeSsRMYAZIBIwoKcHJvamVjdF9pZBIVQhMzNTQ1MjA3MTUyNzE3MzE3NTYz&filename=&opi=89354086", "path": "stitch_screens/splash_screen.html"},
    
    # Search Screen
    {"url": "https://lh3.googleusercontent.com/aida/ADBb0ujBK-LKgjmByOyGzfWrZZu9EalMtBxbpEqqGr-UYyeqi_q-EbduWOtt4lIXMm5X6eq6nwyFGE5MViYoSC5SzflsOrUAC08-nQkjcyfnHraIE-_-5g_XlgSDFcouwF-b-aBwUqLWnkbx07MkCU_UxwvIlHTedj9ClA0U_g5Y-PblKH6hjxx1_8lFmtFIaEcMifgKVM5TbtKwQvaaNh1fttE2c4kbbLjTcaNSmcdhZjVRGe-TJvxhP2gpvHQ", "path": "stitch_screens/search_screen.png"},
    {"url": "https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ7Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpaCiVodG1sXzMzYTRhZjAzNDVmMjRjMTBiODVmNjlmNWEwZDk1ODhmEgsSBxDV5eeSsRMYAZIBIwoKcHJvamVjdF9pZBIVQhMzNTQ1MjA3MTUyNzE3MzE3NTYz&filename=&opi=89354086", "path": "stitch_screens/search_screen.html"},
    
    # Login Screen
    {"url": "https://lh3.googleusercontent.com/aida/ADBb0uh8IJjlWqD-npO-aZmrp_06OmRsz42JI1_gSSHONr-_6bNGWAt5uwJKmuteVxMLY7lbO8h0gBC5D9fzD668GG2aff4KYCb1csdXHs4bSQR2Yi2K5A-cAn2P3IHDm64iImBu-qrXc4uX54PA5hO5-N9XkadUnSEwzmr_qcPwOESEWIyYHp55gLSuCUP_qumGA-GXiffJH61wuzyt8eOGW8q0keQduxIEgusdVpGa8npYl0IX3EPIgxSO910", "path": "stitch_screens/login_screen.png"},
    {"url": "https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ7Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpaCiVodG1sX2U2YmQ5ZjQ1YjE2NTQ0MzZhZWNkZWYzODllYzBlMjRlEgsSBxDV5eeSsRMYAZIBIwoKcHJvamVjdF9pZBIVQhMzNTQ1MjA3MTUyNzE3MzE3NTYz&filename=&opi=89354086", "path": "stitch_screens/login_screen.html"},
    
    # Profile Screen
    {"url": "https://lh3.googleusercontent.com/aida/ADBb0uhzD6H_DJSCi3qigRF1JQ-6aFRAhoIFAihG8pAY6CMIWly_itY92XddHFz0pNUcDkjPdEfD3ORmsDx4HbhiMrFGZ_6XMzRoJn07n9pPRdys1tpyu2tENyS5aqtQFeRH2RkJVS6QjONTaYg_-ZI0X1hPbE2lCUIvJz4g6-NrfIsGAHGDzlwZq7lUxwwcHSMB2cg7AfUE0DwbBMlRZH0EuHlO19_xNNi27zg2q7hJ9nsYrErhidWA5Bt14w", "path": "stitch_screens/profile_screen.png"},
    {"url": "https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ7Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpaCiVodG1sX2ExM2ZiZjMwYzdlYzRkYjBhN2ZmOTUzMTJlZjljMGZkEgsSBxDV5eeSsRMYAZIBIwoKcHJvamVjdF9pZBIVQhMzNTQ1MjA3MTUyNzE3MzE3NTYz&filename=&opi=89354086", "path": "stitch_screens/profile_screen.html"},
]

for d in downloads:
    print(f"Downloading {d['path']}...")
    req = urllib.request.Request(d['url'], headers={'User-Agent': 'Mozilla/5.0'})
    try:
        with urllib.request.urlopen(req) as response, open(d['path'], 'wb') as out_file:
            data = response.read()
            out_file.write(data)
    except Exception as e:
        print(f"Failed to download {d['path']}: {e}")
