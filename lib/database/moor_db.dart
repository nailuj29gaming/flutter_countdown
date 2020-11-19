import 'package:countdown/database/repeat_type.dart';
import 'package:moor_flutter/moor_flutter.dart';

part 'moor_db.g.dart';

/// Schema for the database
class Countdowns extends Table {
  /// Autogenerated id for the countdown.
  IntColumn get id => integer().autoIncrement()();

  /// The countdown's name.
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// The date to count down to.
  DateTimeColumn get date => dateTime()();

  /// Whether or not the countdown repeats.
  ///
  /// If this is `true`, [repeatType] is required, but this is not enforced in the database code
  BoolColumn get repeats => boolean().withDefault(Constant(false))();

  /// The repeat interval for the countdown.
  ///
  /// This will be mapped to a [RepeatType] by [RepeatConverter]
  IntColumn get repeatType =>
      integer().map(const RepeatConverter()).nullable()();
}

/// The database logic for the app
@UseMoor(tables: [Countdowns])
class AppDatabase extends _$AppDatabase {
  /// Constructs the `AppDatabase`
  ///
  /// This is only used when initializing the `Provider` to prevent data races
  AppDatabase()
      : super(FlutterQueryExecutor.inDatabaseFolder(
            path: "countdowns.db", logStatements: true));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(onCreate: (Migrator m) {
        return m.createAll();
      }, onUpgrade: (Migrator m, int from, int to) async {
        if (from == 1 && to == 2) {
          await m.addColumn(countdowns, countdowns.repeats);
          await m.addColumn(countdowns, countdowns.repeatType);
        }
      });

  // Create
  Future<int> insertCountdown(CountdownsCompanion countdown) =>
      into(countdowns).insert(countdown);

  // Read
  Future<List<Countdown>> getCountdowns() => select(countdowns).get();
  Stream<List<Countdown>> watchCountdowns() => select(countdowns).watch();
  Stream<List<Countdown>> watchCountdownsByDate() => (select(countdowns)
        ..orderBy([(countdown) => OrderingTerm(expression: countdown.date)]))
      .watch();

  // Update
  Future<bool> updateCountdown(Countdown countdown) =>
      update(countdowns).replace(countdown);

  // Delete
  Future<int> deleteCountdown(Countdown countdown) =>
      delete(countdowns).delete(countdown);
}
