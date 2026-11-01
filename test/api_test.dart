import 'package:flutter_test/flutter_test.dart';
import 'package:ziesocial/core/constants.dart';
import 'package:ziesocial/core/network.dart';
import 'package:ziesocial/viewmodel/home_viewmodel.dart';

void main() {
  test('verify ApiConstants URLs and Image URL with localhost', () {
    expect(ApiConstants.rootUrl, equals('http://localhost/ziesocial'));
    expect(ApiConstants.readPosts, equals('http://localhost/ziesocial/api/posts/read.php'));

    final sampleImagePath = 'uploads/posts/post_6ac7904c29f0f0.78338892.jpg';
    final fullImageUrl = ApiConstants.getImageUrl(sampleImagePath);
    expect(
      fullImageUrl,
      equals('http://localhost/ziesocial/uploads/posts/post_6ac7904c29f0f0.78338892.jpg'),
    );
  });

  test('fetch posts from localhost API and verify images exist', () async {
    final client = ApiClient();
    final vm = HomeViewModel(client);

    await vm.fetchPosts();

    expect(vm.errorMessage, isNull);
    expect(vm.posts.isNotEmpty, isTrue);

    final first = vm.posts.first;
    expect(first.image, isNotNull);
    final imageUrl = ApiConstants.getImageUrl(first.image);
    expect(imageUrl, startsWith('http://localhost/ziesocial/uploads/posts/'));
  });
}
