// EXAMPLE ONLY — do not paste blindly into database_service.dart.
// Your existing DB is version 10. Back it up and test this migration on a COPY
// before changing the version. This adds cloud_id/sync_status columns without
// deleting existing rows. Apply equivalent logic to every table you intend
// to sync, and write a table-specific adapter for its fields.
//
// Example inside your existing onUpgrade callback:
//
// if (oldVersion < 11) {
//   for (final table in [
//     'beneficiaries', 'visits', 'pregnancies',
//     'children', 'asha_workers', 'daily_work',
//   ]) {
//     final columns = await db.rawQuery('PRAGMA table_info($table)');
//     final names = columns.map((c) => c['name'] as String).toSet();
//     if (!names.contains('cloud_id')) {
//       await db.execute('ALTER TABLE $table ADD COLUMN cloud_id TEXT');
//     }
//     if (!names.contains('sync_status')) {
//       await db.execute(
//         "ALTER TABLE $table ADD COLUMN sync_status TEXT DEFAULT 'pending'",
//       );
//     }
//   }
// }
//
// This is not a complete sync adapter. Add UUID generation and conflict rules
// before using it. Existing beneficiaries already have sync_id; decide on one
// canonical field rather than creating two IDs for that table.
