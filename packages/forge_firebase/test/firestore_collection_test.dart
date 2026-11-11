import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_core/forge_core.dart';
import 'package:forge_firebase/forge_firebase.dart';

typedef Note = ({String id, String text});

void main() {
  late FirestoreCollection<Note> notes;

  setUp(() {
    notes = FirestoreCollection<Note>(
      firestore: FakeFirebaseFirestore(),
      path: 'notes',
      fromMap: (id, data) => (id: id, text: data['text'] as String),
      toMap: (note) => {'text': note.text},
    );
  });

  test('add then get round-trips and uses the document id', () async {
    final id = await notes.add((id: '', text: 'hello'));
    expect(await notes.get(id), (id: id, text: 'hello'));
  });

  test('get throws NotFoundFailure for a missing document', () {
    expect(notes.get('missing'), throwsA(isA<NotFoundFailure>()));
  });

  test('list applies the query builder', () async {
    await notes.set('a', (id: 'a', text: 'x'));
    await notes.set('b', (id: 'b', text: 'y'));
    final result = await notes.list((q) => q.where('text', isEqualTo: 'y'));
    expect(result, [(id: 'b', text: 'y')]);
  });

  test('update and delete change the document', () async {
    await notes.set('a', (id: 'a', text: 'x'));
    await notes.update('a', {'text': 'z'});
    expect((await notes.get('a')).text, 'z');
    await notes.delete('a');
    expect(await notes.watch('a').first, isNull);
  });
}
