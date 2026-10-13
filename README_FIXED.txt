ASHA Sarthi - fixed project

LOGIN
- Login screen uses Email + Password + Role.
- Backend /login uses the same three fields.
- Roles accepted: asha_worker, supervisor, beneficiary.
- Existing database rows using "ASHA Worker" are normalized by the backend login query.

ANDROID EMULATOR
ApiService uses http://10.0.2.2:8000 because the Android emulator reaches the Windows host through 10.0.2.2.

START BACKEND
1. Open CMD 1.
2. cd C:\Users\SOUNDARYA\my_project\backend
3. uvicorn main:app --reload --host 0.0.0.0 --port 8000

START FLUTTER
1. Open CMD 2.
2. cd C:\Users\SOUNDARYA\my_project
3. flutter clean
4. flutter pub get
5. flutter run -d emulator-5554

IMPORTANT
Keep the backend CMD running while the Flutter app is running.
The backend still requires MySQL database 'ashasarthi' and the credentials configured in backend/database.py and backend/main.py.


MULTI-DEVICE / REAL PHONE SETUP
1. Keep the backend on the Windows PC:
   cd C:\Users\SOUNDARYA\my_project\backend
   python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000

2. Put the Windows PC and BOTH phones on the SAME Wi-Fi network.
3. On Windows run: ipconfig
4. Find the active adapter's IPv4 Address, for example 192.168.1.5.
5. Allow Python/Uvicorn through Windows Firewall, or allow inbound TCP port 8000.
6. Run/build the phone app using:
   flutter run -d RMX3844 --dart-define=API_BASE_URL=http://192.168.1.5:8000
   Replace 192.168.1.5 with your actual PC IPv4 address.
7. For a release APK:
   flutter build apk --release --dart-define=API_BASE_URL=http://192.168.1.5:8000
8. Install the SAME release APK on both phones while they are on the same Wi-Fi.

HOW SHARING WORKS
- Each phone keeps a local SQLite copy for offline use.
- When the backend is reachable, new beneficiary records are synchronized to MySQL.
- The supervisor dashboard reads the central MySQL database, so records synchronized from phone A appear on phone B/supervisor after refresh/login.
- If there is no network, the record remains local and will sync when connectivity returns.
- Do not use 10.0.2.2 on a physical phone; that address is for the Android emulator.

PHYSICAL PHONE IMPORTANT
========================
Do not use 10.0.2.2 on a physical phone. Use build_phone.bat and enter the PC's
Wi-Fi IPv4 address. Keep phone and PC on the same Wi-Fi and start FastAPI with
--host 0.0.0.0 --port 8000.
