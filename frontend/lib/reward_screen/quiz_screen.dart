import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:frontend/api_services/quiz_service.dart';
import 'package:frontend/components/standard_app_bar.dart';
import 'package:frontend/models/quiz_model.dart';
import 'package:frontend/theme.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Quiz> quizzes = [];
  int currentQuestionIndex = 0;
  int index = 0; // global progress index
  bool isLoading = false;
  int coins = 0;
  String selectedAnswer = '';
  bool isAnswerChecked = false;
  bool _quizCompleted = false;

  @override
  void initState() {
    super.initState();
    startQuiz();
  }

  Future<void> startQuiz() async {
    setState(() => isLoading = true);
    try {
      final response = await QuizApiService.fetchQuizzes();
      setState(() {
        quizzes = response.quizzes;
        index = response.currentQuestionIndex;
      });
    } catch (e) {
      showError('Error fetching quizzes: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// Calculates how many questions have been completed in this session
  int getCompletedQuestionCount() {
    return currentQuestionIndex + (isAnswerChecked ? 1 : 0);
  }

  Future<void> updateProgress() async {
    try {
      await QuizApiService.updateProgress(
        currentQuestionIndex: index + getCompletedQuestionCount(),
      );
    } catch (e) {
      showError(e.toString());
    }
  }

  void handleAnswer(String answer) {
    if (isAnswerChecked) return;

    final correctAnswer = quizzes[currentQuestionIndex].answer;

    setState(() {
      selectedAnswer = answer;
      isAnswerChecked = true;
    });

    if (answer == correctAnswer) {
      coins += 10;
    }

    Future.delayed(const Duration(seconds: 1), () async {
      if (currentQuestionIndex < quizzes.length - 1) {
        setState(() {
          currentQuestionIndex++;
          selectedAnswer = '';
          isAnswerChecked = false;
        });
      } else {
        // Final question answered
        await updateProgress();
        try {
          await QuizApiService.addCoins(coins: coins);
        } catch (e) {
          showError(e.toString());
        }
        showScorePopup();
      }
    });
  }

  void handleQuit() async {
    await updateProgress();
    try {
      await QuizApiService.addCoins(coins: coins);
    } catch (e) {
      showError('Failed to update coins: $e');
    }
    setState(() => _quizCompleted = true); // Mark quiz as completed
    showScorePopup();
  }

  void showScorePopup() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Quiz Completed!"),
        content: Text("Coins earned: $coins / ${quizzes.length * 10}"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true); // close dialog
              Navigator.of(context).pop(true); // go back
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Color getOptionColor(String option) {
    final correctAnswer = quizzes[currentQuestionIndex].answer;
    if (!isAnswerChecked) return AppColors.secondary;

    if (option == correctAnswer) {
      return Colors.green.withValues(alpha: 0.5);
    } else if (option == selectedAnswer) {
      return Colors.red.withValues(alpha: 0.5);
    } else {
      return AppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        // Allow back if quiz is completed
        if (_quizCompleted) return true;

        // Show confirmation dialog
        final shouldQuit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Quit Quiz?'),
            content: const Text(
                'Your progress will be saved. You will earn coins for the questions you have answered correctly so far.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Quit'),
              ),
            ],
          ),
        );

        if (shouldQuit == true) {
          handleQuit();
        }
        return false; // Prevent default back behavior
      },
      child: Scaffold(
        appBar: StandardAppBar(
          appBarTitle: 'Quiz',
          showBackButton: true,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : quizzes.isEmpty
                ? const Center(child: Text("No quiz available"))
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceEvenly, // spread evenly
                          children: [
                            Expanded(
                              child: DotsIndicator(
                                dotsCount: quizzes.length,
                                position: currentQuestionIndex.toDouble(),
                                decorator: DotsDecorator(
                                  color: Colors.grey,
                                  activeColor: AppColors.primary,
                                  size: const Size(23.0, 9.0),
                                  activeSize: const Size(23.0, 9.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5.0),
                                  ),
                                  activeShape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5.0),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const SizedBox(height: 20),
                        Text(
                          quizzes[currentQuestionIndex].question,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        ...quizzes[currentQuestionIndex].options.map((option) {
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: getOptionColor(option),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  width: 0.1, color: AppColors.primary),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: 0.1), // shadow color
                                  blurRadius: 8, // softness of the shadow
                                  offset: const Offset(0, 2), // position (x,y)
                                ),
                              ],
                            ),
                            child: ListTile(
                              title: Center(
                                child: Text(
                                  option,
                                  style: const TextStyle(
                                      color: AppColors.blackText),
                                ),
                              ),
                              onTap: () => handleAnswer(option),
                            ),
                          );
                        }),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: handleQuit,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary),
                              child: const Text(
                                "Quit",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
