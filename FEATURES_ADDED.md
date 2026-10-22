# AshaSarthi – Integrated Feature Set

This project keeps the existing Flutter + FastAPI + MySQL + offline SQLite architecture and adds the requested modules.

## Requested features implemented

1. **Supervisor payment management**
   - Supervisor can open Payments from the dashboard.
   - Add ASHA payment records by worker, month, year and work counts.
   - Mark a payment as Paid.
   - When a payment is marked Paid, an in-app notification is created for the ASHA worker.

2. **Beneficiary VHNC + disease**
   - Beneficiary form already contains VHNC selection and disease selection.
   - Values are stored locally and synced to MySQL.
   - Supervisor and ASHA dashboards show VHNC and disease with the rest of the beneficiary information.

3. **Messaging + replies**
   - In-app message sending between ASHA workers, beneficiaries and supervisors.
   - Replies are stored as normal messages.
   - Receiver gets a notification.
   - Supervisor gets an audit notification for worker/beneficiary messaging activity.
   - Real carrier SMS is not automatically enabled because an SMS gateway/provider and credentials are required; the backend endpoint is ready for that integration.

4. **Supervisor notifications**
   - Notification table and API.
   - Supervisor can open Notifications and see system activity.
   - Payment and messaging activity can generate notifications.

5. **Language support**
   - English, Marathi and Hindi selector.
   - Selected language is saved locally and survives restart.
   - Common feature labels have translations and the framework is ready to expand to all screens.

6. **Website / browser support**
   - API base URL automatically uses `127.0.0.1:8000` on Flutter Web and `10.0.2.2:8000` on the Android emulator.
   - Build/run with `flutter run -d chrome` or `flutter build web`.

## Run

### Backend
```bash
cd backend
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Android emulator
```bash
flutter clean
flutter pub get
flutter run -d emulator-5554
```

### Browser
```bash
flutter clean
flutter pub get
dart run sqflite_common_ffi_web:setup
flutter run -d chrome
```

The web SQLite adapter uses IndexedDB and requires the package setup step to place its WASM/shared-worker files in `web/`. citeturn0search0turn0search1

Backend Swagger:
`http://127.0.0.1:8000/docs`

Backend health check:
`http://127.0.0.1:8000/`

## Important

The MySQL database must be running and the `ashasarthi` database must exist. The FastAPI startup migration creates the added payment, messages and notifications tables automatically.
