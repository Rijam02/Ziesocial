import 'package:flutter/foundation.dart';
import 'package:ziesocial/core/constants.dart';
import 'package:ziesocial/core/network.dart';
import 'package:ziesocial/model/comment_model.dart';

class CommentsViewModel extends ChangeNotifier {
  final ApiClient _apiClient;

  CommentsViewModel(this._apiClient);

  List<CommentModel> _comments = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<CommentModel> get comments => _comments;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<void> fetchComments(int postId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(
        '${ApiConstants.readComments}?post_id=$postId',
      );
      final rawData = response['data'];
      if (rawData is List) {
        _comments = rawData
            .map((item) => CommentModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _comments = [];
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int?> addComment({
    required int postId,
    required int userId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return null;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post(
        ApiConstants.createComment,
        body: {
          'post_id': postId,
          'user_id': userId,
          'text': text.trim(),
        },
      );

      if (response['comment'] != null) {
        final newComment = CommentModel.fromJson(
          response['comment'] as Map<String, dynamic>,
        );
        _comments.add(newComment);
      }

      final int updatedCount = response['comment_count'] is int
          ? response['comment_count'] as int
          : _comments.length;

      notifyListeners();
      return updatedCount;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<int?> deleteComment({
    required int commentId,
    required int userId,
    required int postId,
  }) async {
    final index = _comments.indexWhere((c) => c.id == commentId);
    if (index == -1) return null;

    final removed = _comments.removeAt(index);
    notifyListeners();

    try {
      final response = await _apiClient.post(
        ApiConstants.deleteComment,
        body: {
          'comment_id': commentId,
          'user_id': userId,
        },
      );

      final int updatedCount = response['comment_count'] is int
          ? response['comment_count'] as int
          : _comments.length;

      return updatedCount;
    } catch (e) {
      // Revert if error
      _comments.insert(index, removed);
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }
}
