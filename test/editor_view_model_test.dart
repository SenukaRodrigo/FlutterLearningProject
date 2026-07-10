// The editor's publish flow, exercised against the mock repository.

import 'package:flutter_test/flutter_test.dart';

import 'package:inkflow/data/repositories/post_repository.dart';
import 'package:inkflow/ui/features/editor/view_models/editor_view_model.dart';

void main() {
  late MockPostRepository repository;
  late EditorViewModel viewModel;

  setUp(() {
    repository = MockPostRepository();
    viewModel = EditorViewModel(repository);
  });

  tearDown(() => repository.dispose());

  test('an empty draft reports why it cannot be published', () {
    expect(viewModel.validationError, 'Add a title before publishing.');

    viewModel.updateTitle('A title');
    expect(viewModel.validationError, 'Write some content before publishing.');

    viewModel.updateBody('Some content.');
    expect(viewModel.validationError, isNull);
  });

  test('publishing an invalid draft creates nothing', () async {
    viewModel.updateTitle('   ');
    viewModel.updateBody('Some content.');

    expect(await viewModel.publish(), isNull);
    expect(await repository.fetchFeed(), hasLength(6));
  });

  test('publishing creates a retrievable post at the top of the feed',
      () async {
    viewModel.updateTitle('  Testing the editor  ');
    viewModel.updateBody('  Body written in **Markdown**.  ');
    viewModel.updateTags('flutter, testing, ');

    final publishing = viewModel.publish();
    expect(viewModel.isPublishing, isTrue);

    final post = await publishing;
    expect(viewModel.isPublishing, isFalse);

    expect(post, isNotNull);
    expect(post!.title, 'Testing the editor');
    expect(post.body, 'Body written in **Markdown**.');
    expect(post.tags, ['flutter', 'testing']);
    expect(post.author.id, repository.currentAuthor.id);

    expect(await repository.fetchPost(post.id), isNotNull);
    expect((await repository.fetchFeed()).first.id, post.id);
  });

  test('reset empties the draft', () {
    viewModel.updateTitle('A title');
    viewModel.updateBody('Some content.');
    viewModel.updateTags('flutter');

    viewModel.reset();

    expect(viewModel.title, isEmpty);
    expect(viewModel.body, isEmpty);
    expect(viewModel.tagsInput, isEmpty);
  });
}
