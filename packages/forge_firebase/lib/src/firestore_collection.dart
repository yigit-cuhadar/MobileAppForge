import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:forge_core/forge_core.dart';

/// Typed access to one Firestore collection. Use as (or inside) a feature's
/// remote data source; it throws, and the repository wraps calls in `guard`.
class FirestoreCollection<T> {
  FirestoreCollection({
    required FirebaseFirestore firestore,
    required String path,
    required T Function(String id, Map<String, dynamic> data) fromMap,
    required Map<String, dynamic> Function(T value) toMap,
  }) : _ref = firestore
           .collection(path)
           .withConverter<T>(
             fromFirestore: (snap, _) => fromMap(snap.id, snap.data()!),
             toFirestore: (value, _) => toMap(value),
           );

  final CollectionReference<T> _ref;

  /// Throws [NotFoundFailure] when the document does not exist.
  Future<T> get(String id) async {
    final snap = await _ref.doc(id).get();
    return snap.data() ?? (throw NotFoundFailure('${_ref.path}/$id'));
  }

  Future<List<T>> list([Query<T> Function(Query<T> q)? build]) async {
    final snap = await (build?.call(_ref) ?? _ref).get();
    return [for (final doc in snap.docs) doc.data()];
  }

  Stream<T?> watch(String id) =>
      _ref.doc(id).snapshots().map((snap) => snap.data());

  Stream<List<T>> watchList([Query<T> Function(Query<T> q)? build]) =>
      (build?.call(_ref) ?? _ref).snapshots().map(
        (snap) => [for (final doc in snap.docs) doc.data()],
      );

  /// Creates a document with a generated id and returns that id.
  Future<String> add(T value) async => (await _ref.add(value)).id;

  Future<void> set(String id, T value) => _ref.doc(id).set(value);

  /// Partial update with raw field names.
  Future<void> update(String id, Map<String, Object?> fields) =>
      _ref.doc(id).update(fields);

  Future<void> delete(String id) => _ref.doc(id).delete();
}
