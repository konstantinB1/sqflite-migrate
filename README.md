# sqflite_migrate

Proper, and traditional way to do migrations in [sqflite](https://pub.dev/packages/sqflite_common_ffi)

- Supports using plain `sql` syntax to create migration files
- A working CLI with all the necessary commands
- A programmatic for more fine grained control

# Usage

`dart pub global activate sqflite_migrate`

This will give you access to global cli from [pub.dev](pub.dev) website

# Create your migrations folder

Create migrations folder wherever you think its most suitable for your app, and fill it with migration
files

```sql
-- UP --
CREATE TABLE IF NOT EXISTS my_table (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL
);

-- DOWN --
DROP TABLE my_table;
```

`-- UP --` and `-- DOWN --` are just plain sql comments required to separate the `up` and `down` queries

You can write as many queries as you want in the `up` and `down` sections, as long as the statements are separated by `;` delimiter

```sql

-- UP --
CREATE TABLE IF NOT EXISTS my_table (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS my_table2 (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL
);

-- DOWN --
DROP TABLE my_table;
DROP TABLE my_table2;
```

# Naming format

The migration files should be named in the following format

`<version>_<description>.sql`

Currently the version format is just a simple integer, that should be incremental, and sorted in ascending order that you want to run the migrations to run

In next releases we will add `create` command in the cli, with options to create it with a timestamp, or a version number

# Running the migrations

`sqflite_migrate` cli has the following commands

- `migrate --database DB_PATH --path MIGRATIONS_FOLDER_PATH [OPTIONS]` - Runs the migrations
- `rollback --database DB_PATH --path MIGRATIONS_FOLDER_PATH [OPTIONS]` - Rolls back the migrations
- `status --database DB_PATH --path MIGRATIONS_FOLDER_PATH` - Shows the current status of the migrations
- `clear --database DB_PATH` - Clears all the records from migrations table
- `delete-db --database DB_PATH` - Deletes the database file, and all the migrations records

# Programmatic usage

You can also use the `MigrationRunner` class to run the migrations programmatically, but it is not recommended to use it in production, as it is not properly tested for this approach

```dart
import 'package:sqflite_migrate/sqflite_migrate.dart';

void main() async {
  final migrator = MigrationRunner.init(
    database: 'path/to/db',
    migrationsPath: 'path/to/migrations',
  );

  await migrator.migrate()..rollback();
}
```

# Coming up

- Add `create` command in the cli
- Add `timestamp` and `version` options in the `create` command
- Add `--force` option in the `migrate` command to force run all the migrations
- Add `--force` option in the `rollback` command to force rollback all the migrations
