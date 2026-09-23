import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'flashcards_page.dart';
import '../../../../services/user_progress_service.dart';

class QuizPage extends StatefulWidget {
  final VoidCallback? onQuizComplete;

  const QuizPage({super.key, this.onQuizComplete});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  // Dynamic question list populated from curatedQuizBanks by selected module
  late List<_QuizQuestion> _questions;

  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _answered = false;
  String? _selected;
  late List<String> _shuffledOptions;
  final Random _random = Random();
  String _selectedModule = 'Luzon'; // default module
  late final List<String> _modules =
      curatedQuizBanks.keys.toList(growable: false); // ['Luzon','Visayas','Mindanao','Aswang','Deity']

  @override
  void initState() {
    super.initState();
    _loadModule(_selectedModule, randomize: true);
  }

  List<_QuizQuestion> _buildFromBank(String module) {
    final bank = curatedQuizBanks[module] ?? curatedQuizBanks['Luzon']!;
    return bank
        .map((m) => _QuizQuestion(
              question: m['question'] as String,
              options: List<String>.from(m['options'] as List),
              correctAnswer: m['answer'] as String,
            ))
        .toList();
  }

  void _loadModule(String module, {bool randomize = false}) {
    _selectedModule = module;
    _questions = _buildFromBank(module);
    _resetQuiz(randomize: randomize);
  }

  void _prepareCurrentQuestion() {
    _answered = false;
    _selected = null;
    _shuffledOptions = List<String>.from(_questions[_currentQuestionIndex].options);
    _shuffledOptions.shuffle(_random);
  }

  void _resetQuiz({bool randomize = false}) {
    if (randomize) _questions.shuffle(_random);
    _currentQuestionIndex = 0;
    _score = 0;
    _prepareCurrentQuestion();
    setState(() {});
  }

  void _answer(String selected) {
    if (_answered) return;
    setState(() {
      _answered = true;
      _selected = selected;
      if (selected == _questions[_currentQuestionIndex].correctAnswer) {
        _score++;
      }
    });
  }

  Future<void> _finishQuiz() async {
    final total = _questions.length;
    final perfect = _score == total;
    // Track progress in Hive
    await UserProgressService.instance.incrementCounter('quizzes_completed');
    await UserProgressService.instance.incrementCounter('quizzes_completed:${_selectedModule.toLowerCase()}');
    if (perfect) {
      await UserProgressService.instance.unlockBadge('quiz_perfect_${_selectedModule.toLowerCase()}');
    }
    _showResult(perfect: perfect);
  }

  void _nextOrFinish() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _prepareCurrentQuestion();
      });
    } else {
      _finishQuiz();
    }
  }

  void _showResult({required bool perfect}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Quiz Completed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Module: $_selectedModule'),
            const SizedBox(height: 8),
            Text('Your score: $_score / ${_questions.length}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (perfect)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade400),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Badge Unlocked: Perfect $_selectedModule Quiz',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetQuiz(randomize: true);
            },
            child: const Text('Retry'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (widget.onQuizComplete != null) {
                widget.onQuizComplete!();
              }
            },
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_currentQuestionIndex];
    final total = _questions.length;
    final current = _currentQuestionIndex + 1;
    final progress = current / total;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mythology Quiz'),
        actions: [
          IconButton(
            tooltip: 'Flashcards',
            icon: const Icon(Icons.style),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FlashcardsPage()));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Module selector (horizontal ChoiceChips)
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _modules.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final m = _modules[i];
                  final selected = m == _selectedModule;
                  return ChoiceChip(
                    label: Text(m),
                    selected: selected,
                    onSelected: (_) {
                      if (!selected) {
                        _loadModule(m, randomize: true);
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(value: progress, minHeight: 10),
                  ),
                ),
                const SizedBox(width: 12),
                Text('$_score/$total', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$_selectedModule • Question $current of $total',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: Theme.of(context).colorScheme.primary)),
                    const SizedBox(height: 8),
                    Text(
                      q.question,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: _shuffledOptions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final option = _shuffledOptions[index];
                  final isCorrect = option == q.correctAnswer;
                  final isSelected = option == _selected;
                  Color? bg;
                  Color? fg;
                  if (_answered) {
                    if (isCorrect) {
                      bg = Colors.green.shade50;
                      fg = Colors.green.shade800;
                    } else if (isSelected) {
                      bg = Colors.red.shade50;
                      fg = Colors.red.shade800;
                    } else {
                      bg = Theme.of(context).colorScheme.surfaceVariant;
                      fg = Theme.of(context).colorScheme.onSurfaceVariant;
                    }
                  }
                  return InkWell(
                    onTap: _answered ? null : () => _answer(option),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: bg ?? Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _answered
                              ? (isCorrect
                                  ? Colors.green.shade300
                                  : isSelected
                                      ? Colors.red.shade300
                                      : Theme.of(context).colorScheme.outlineVariant)
                              : Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              option,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(color: fg ?? Theme.of(context).colorScheme.onSurface),
                            ),
                          ),
                          if (_answered)
                            Icon(
                              isCorrect
                                  ? Icons.check_circle_rounded
                                  : isSelected
                                      ? Icons.cancel_rounded
                                      : Icons.radio_button_unchecked,
                              color: isCorrect
                                  ? Colors.green.shade700
                                  : isSelected
                                      ? Colors.red.shade700
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: !_answered
                      ? () {
                          setState(() {
                            _answered = true;
                            _selected = null; // skipped
                          });
                        }
                      : null,
                  child: const Text('Skip'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _answered ? _nextOrFinish : null,
                  child: Text(_currentQuestionIndex < total - 1 ? 'Next' : 'Finish'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizQuestion {
  final String question;
  final List<String> options;
  final String correctAnswer;

  _QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
  });
}

// Curated quiz banks by Region and Category
final Map<String, List<Map<String, dynamic>>> curatedQuizBanks = {
  'Luzon': [
    {
      'question':
          'Which cigar-smoking giant from Luzon is known to sit on the branches of large trees like the Balete?',
      'options': ['Kapre', 'Tikbalang', 'Bungisngis', 'Nuno sa Punso'],
      'answer': 'Kapre',
    },
    {
      'question':
          'Which creature has the head and hooves of a horse and disproportionately long limbs that wrap past its head when squatting?',
      'options': ['Sigbin', 'Tikbalang', 'Minokawa', 'Kapre'],
      'answer': 'Tikbalang',
    },
    {
      'question':
          'Which creature from Bagobo/Luzon lore is a massive dragon-like bird with steel feathers capable of swallowing the moon?',
      'options': ['Sarimanok', 'Minokawa', 'Bakunawa', 'Dalikamata'],
      'answer': 'Minokawa',
    },
    {
      'question':
          'Which giant creature is known for having a single eye in the center of its forehead and a constant, terrifying laugh?',
      'options': ['Bungisngis', 'Kapre', 'Tikbalang', 'Bata Mama'],
      'answer': 'Bungisngis',
    },
    {
      'question':
          'Which small old man is said to inhabit anthills or termite mounds and demands respect from people passing by?',
      'options': ['Nuno sa Punso', 'Sigbin', 'Bungisngis', 'Santilmo'],
      'answer': 'Nuno sa Punso',
    }
  ],
  'Visayas': [
    {
      'question':
          'Which Visayan creature detaches its upper torso, sprouts bat-like wings, and leaves its lower lower limbs behind at night?',
      'options': ['Manananggal', 'Sigbin', 'Bakunawa', 'Dalikamata'],
      'answer': 'Manananggal',
    },
    {
      'question':
          'Which hornless, goat-like creature walks backward with its head lowered between its hind legs and claps its large ears?',
      'options': ['Tikbalang', 'Sigbin', 'Kapre', 'Nuno sa Punso'],
      'answer': 'Sigbin',
    },
    {
      'question':
          'Which legendary Visayan sea serpent or deity is famously known for swallowing the seven moons?',
      'options': ['Minokawa', 'Bakunawa', 'Sarimanok', 'Santilmo'],
      'answer': 'Bakunawa',
    },
    {
      'question':
          'Which multi-eyed benevolent entity tracks human actions and has a body covered in hundreds of clairvoyant eyes?',
      'options': ['Dalikamata', 'Sarimanok', 'Bata Mama', 'Manananggal'],
      'answer': 'Dalikamata',
    }
  ],
  'Mindanao': [
    {
      'question':
          'Which legendary Mindanaoan bird features colorful, metallic feathers and holds a fresh fish in its beak or talons?',
      'options': ['Minokawa', 'Sarimanok', 'Bakunawa', 'Dalikamata'],
      'answer': 'Sarimanok',
    },
    {
      'question':
          'Which powerful ancestral warrior spirit or protector is celebrated in the traditional epic folklores of Mindanao?',
      'options': ['Bata Mama', 'Kapre', 'Tikbalang', 'Bungisngis'],
      'answer': 'Bata Mama',
    },
    {
      'question':
          'Which floating orb of blazing fire represents lost souls wandering through rural fields and forests?',
      'options': ['Santilmo', 'Sigbin', 'Nuno sa Punso', 'Bakunawa'],
      'answer': 'Santilmo',
    }
  ],
  'Aswang': [
    {
      'question':
          'What structural property defines the nocturnal hunting flight of the legendary Visayan Manananggal?',
      'options': [
        'Detachment of the upper visceral torso',
        'Shapeshifting into a golden moon bird',
        'Vanishing completely into smoke',
        'Walking backward on two hooves'
      ],
      'answer': 'Detachment of the upper visceral torso',
    }
  ],
  'Deity': [
    {
      'question':
          'In ancient cosmic folklore, what catastrophic event is triggered when the Bakunawa or Minokawa swallows a lunar body?',
      'options': ['An Eclipse', 'A Volcanic Eruption', 'A Typhoon', 'An Earthquake'],
      'answer': 'An Eclipse',
    }
  ],
};
