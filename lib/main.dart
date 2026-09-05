// ============================================================
// main.dart
// RSW svarcOS — главный экран приложения
// ============================================================

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'data/models/welding_parameters.dart';
import 'data/models/calculated_parameters.dart';
import 'domain/usecases/calculate_parameters_usecase.dart';
import 'data/datasources/machine_specs.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RSW svarcOS',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  // ==================== СОСТОЯНИЕ ====================
  late WeldingParameters _params;
  Map<String, List<FlSpot>> _cyclogramData = {};
  int _selectedTab = 0;

  // ==================== КОНТРОЛЛЕРЫ ДЛЯ ТЕКСТОВЫХ ПОЛЕЙ ====================
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  // ==================== СОСТОЯНИЕ ОШИБОК ====================
  String? _thicknessTopError;
  String? _thicknessBottomError;
  String? _strokeError;

  // ==================== ЖИЗНЕННЫЙ ЦИКЛ ====================
  @override
  void initState() {
    super.initState();
    _params = WeldingParameters.defaults();
    _updateCyclogram();
    _initControllers();
  }

  void _initControllers() {
    _controllers['thicknessTop'] = TextEditingController(
      text: _params.thicknessTop.toStringAsFixed(1).replaceFirst('.', ','),
    );
    _controllers['thicknessBottom'] = TextEditingController(
      text: _params.thicknessBottom.toStringAsFixed(1).replaceFirst('.', ','),
    );
    _controllers['stroke'] = TextEditingController(
      text: _params.stroke.toInt().toString(),
    );
    _focusNodes['thicknessTop'] = FocusNode();
    _focusNodes['thicknessBottom'] = FocusNode();
    _focusNodes['stroke'] = FocusNode();
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    for (var node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _updateCyclogram() {
    setState(() {
      _cyclogramData = _generateCyclogramData();
    });
  }

  void _updateControllerText(String key, String text) {
    if (_controllers[key]?.text != text) {
      _controllers[key]?.text = text;
    }
  }

  // ==================== ДЕЙСТВИЯ ====================
  void _resetParameters() {
    setState(() {
      _params = WeldingParameters.defaults();
      _thicknessTopError = null;
      _thicknessBottomError = null;
      _strokeError = null;
      _updateControllerText('thicknessTop', _params.thicknessTop.toStringAsFixed(1).replaceFirst('.', ','));
      _updateControllerText('thicknessBottom', _params.thicknessBottom.toStringAsFixed(1).replaceFirst('.', ','));
      _updateControllerText('stroke', _params.stroke.toInt().toString());
      _updateCyclogram();
    });
  }

  void _applyCalculatedParameters(CalculatedParameters result) {
    setState(() {
      final postPower = result.postPower ?? 5;

      // Рассчитываем минимальное offTime для текущей толщины
      final maxPressure = result.forgePressure > result.pressure 
          ? result.forgePressure 
          : result.pressure;
      final minOffTime = (maxPressure / 0.3).ceilToDouble();

      _params = _params.copyWith(
        power: result.power.round().clamp(5, 99),
        weld: result.weld.roundToDouble().clamp(0.5, 99.5),
        pressure: result.pressure.clamp(0.5, 10.0),
        squeeze1: result.squeeze1.roundToDouble().clamp(0.5, 99.5),
        forgePressure: result.forgePressure.clamp(0, 10.0),
        forgeDelay: result.forgeDelay.clamp(0, 99),
        cold3: result.cold3.round().clamp(0, 50),
        postWeld: result.postWeld.roundToDouble().clamp(0, 99.5),
        postPower: postPower,
        holdTime: result.holdTime.roundToDouble().clamp(0.5, 99.5),
        offTime: minOffTime,  // Устанавливаем offTime равным минимуму
      );
      
      _updateCyclogram();
    });
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RSW svarcOS'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: _resetParameters,
            tooltip: 'Сбросить параметры',
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _buildParameterInput(),
          _buildChartView(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (index) => setState(() => _selectedTab = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Параметры'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Циклограмма'),
        ],
      ),
    );
  }

  // ==================== ЭКРАН ПАРАМЕТРОВ ====================
  Widget _buildParameterInput() {
    final hasErrors = _thicknessTopError != null || _thicknessBottomError != null || _strokeError != null;

    // ---- МИНИМАЛЬНОЕ ЗНАЧЕНИЕ OFF TIME = максимальное давление / 0.3 ----
    final maxPressure = _params.forgePressure > _params.pressure 
        ? _params.forgePressure 
        : _params.pressure;
    final minOffTime = (maxPressure / 0.3).ceilToDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ---- ИСХОДНЫЕ ДАННЫЕ ----
          _buildMaterialDropdown(),
          const SizedBox(height: 16),

          _buildCompactParameterField(
            label: 'Толщина верхней детали, мм',
            value: _params.thicknessTop,
            min: 0.5,
            max: _params.thicknessBottom,
            onChanged: (val) {
              setState(() {
                final rounded = (val * 10).round() / 10.0;
                final newVal = rounded.clamp(0.5, _params.thicknessBottom);
                _params = _params.copyWith(
                  thicknessTop: newVal,
                  thicknessBottom: _params.thicknessBottom,
                );
                _thicknessTopError = null;
                _updateControllerText('thicknessTop', newVal.toStringAsFixed(1).replaceFirst('.', ','));
                _updateCyclogram();
              });
            },
            controller: _controllers['thicknessTop']!,
            errorText: _thicknessTopError,
            onValidate: (text) {
              final normalized = text.replaceFirst(',', '.');
              final newVal = double.tryParse(normalized);
              if (newVal == null) {
                setState(() => _thicknessTopError = 'Введите число');
                return false;
              }
              if (newVal < 0.5) {
                setState(() => _thicknessTopError = 'Минимум 0.5 мм');
                return false;
              }
              if (newVal > _params.thicknessBottom) {
                setState(() => _thicknessTopError = 'Не может быть больше нижней толщины');
                return false;
              }
              return true;
            },
          ),
          const SizedBox(height: 8),

          _buildCompactParameterField(
            label: 'Толщина нижней детали, мм',
            value: _params.thicknessBottom,
            min: _params.thicknessTop,
            max: 3.0,
            onChanged: (val) {
              setState(() {
                final rounded = (val * 10).round() / 10.0;
                final newVal = rounded.clamp(_params.thicknessTop, 3.0);
                _params = _params.copyWith(
                  thicknessBottom: newVal,
                  thicknessTop: _params.thicknessTop,
                );
                _thicknessBottomError = null;
                _updateControllerText('thicknessBottom', newVal.toStringAsFixed(1).replaceFirst('.', ','));
                _updateCyclogram();
              });
            },
            controller: _controllers['thicknessBottom']!,
            errorText: _thicknessBottomError,
            onValidate: (text) {
              final normalized = text.replaceFirst(',', '.');
              final newVal = double.tryParse(normalized);
              if (newVal == null) {
                setState(() => _thicknessBottomError = 'Введите число');
                return false;
              }
              if (newVal < _params.thicknessTop) {
                setState(() => _thicknessBottomError = 'Не может быть меньше верхней толщины');
                return false;
              }
              if (newVal > 3.0) {
                setState(() => _thicknessBottomError = 'Максимум 3.0 мм');
                return false;
              }
              return true;
            },
          ),
          const SizedBox(height: 8),

          _buildCompactParameterField(
            label: 'Рабочий ход электродов, мм',
            value: _params.stroke,
            min: 5.0,
            max: 150.0,
            step: 5.0,
            onChanged: (val) {
              setState(() {
                final stepped = (val / 5.0).roundToDouble() * 5.0;
                _params = _params.copyWith(stroke: stepped);
                _strokeError = null;
                _updateControllerText('stroke', stepped.toInt().toString());
                _updateCyclogram();
              });
            },
            controller: _controllers['stroke']!,
            errorText: _strokeError,
            onValidate: (text) {
              final newVal = double.tryParse(text);
              if (newVal == null) {
                setState(() => _strokeError = 'Введите число');
                return false;
              }
              if (newVal < 5.0) {
                setState(() => _strokeError = 'Минимум 5 мм');
                return false;
              }
              if (newVal > 150.0) {
                setState(() => _strokeError = 'Максимум 150 мм');
                return false;
              }
              return true;
            },
            isInt: true,
          ),
          const SizedBox(height: 8),

          _buildNuggetField(),
          const SizedBox(height: 16),

          // ---- КНОПКА РАССЧИТАТЬ ----
          ElevatedButton(
            key: const Key('calculate_button'),
            onPressed: hasErrors
                ? null
                : () {
                    try {
                      final useCase = CalculateParametersUseCase();
                      final result = useCase(
                        thickness: _params.thicknessTop,
                        stroke: _params.stroke,
                      );
                      _applyCalculatedParameters(result);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Параметры рассчитаны и применены'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ Ошибка: $e'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: hasErrors ? Colors.grey : Colors.green.shade700,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: Text(
              hasErrors ? 'Исправьте ошибки' : 'Рассчитать',
              style: TextStyle(fontSize: 16, color: hasErrors ? Colors.black54 : Colors.white),
            ),
          ),
          const SizedBox(height: 16),

          // ---- РАСЧЁТНЫЕ ПАРАМЕТРЫ ----
          _buildParameterCard(
            'Время сжатия электродов',
            'SQUEEZE 1',
            _params.squeeze1,
            (val) {
              setState(() {
                _params = _params.copyWith(squeeze1: val);
                _updateCyclogram();
              });
            },
            0.5,
            99.5,
          ),
          const SizedBox(height: 16),

          _buildParameterCard(
            'Давление/усилие сжатия электродов',
            'PRESSURE',
            _params.pressure,
            (val) {
              setState(() {
                double newForgePressure = _params.forgePressure;
                if (newForgePressure < val) {
                  newForgePressure = val;
                }
                _params = _params.copyWith(
                  pressure: val,
                  forgePressure: newForgePressure,
                );
                _updateCyclogram();
              });
            },
            0.5,
            10.0,
            inputKey: const Key('pressure_field_input'),
          ),
          const SizedBox(height: 16),

          _buildParameterCard(
            'Задержка до проковки',
            'FORGE DELAY',
            _params.forgeDelay.toDouble(),
            (val) {
              setState(() {
                _params = _params.copyWith(forgeDelay: val.toInt());
                _updateCyclogram();
              });
            },
            0,
            99,
          ),
          const SizedBox(height: 8),

          _buildParameterCard(
            'Давление/усилие проковки',
            'FORG.PRESS.',
            _params.forgePressure,
            (val) {
              setState(() {
                if (val >= _params.pressure) {
                  _params = _params.copyWith(forgePressure: val);
                  _updateCyclogram();
                }
              });
            },
            _params.pressure,
            10.0,
          ),
          const SizedBox(height: 16),

          _buildParameterCard(
            'Время предварительного подогрева',
            'PRE-WELD',
            _params.preWeld,
            (val) {
              setState(() {
                _params = _params.copyWith(preWeld: val);
                _updateCyclogram();
              });
            },
            0,
            99.5,
          ),
          const SizedBox(height: 8),

          _buildParameterCard(
            'Мощность/ток предварительного подогрева',
            'PRE-POWER',
            _params.prePower.toDouble(),
            (val) {
              setState(() {
                _params = _params.copyWith(prePower: val.toInt());
                _updateCyclogram();
              });
            },
            5,
            99,
          ),
          const SizedBox(height: 8),

          _buildParameterCard(
            'Пауза 1 — между подогревом и сваркой',
            'COLD 1',
            _params.cold1.toDouble(),
            (val) {
              setState(() {
                _params = _params.copyWith(cold1: val.toInt());
                _updateCyclogram();
              });
            },
            0,
            50,
          ),
          const SizedBox(height: 16),

          _buildParameterCard(
            'Время нарастания тока',
            'SLOPE UP',
            _params.slopeUp.toDouble(),
            (val) {
              setState(() {
                _params = _params.copyWith(slopeUp: val.toInt());
                _updateCyclogram();
              });
            },
            0,
            25,
          ),
          const SizedBox(height: 8),

          _buildParameterCard(
            'Время сварки',
            'WELD',
            _params.weld,
            (val) {
              setState(() {
                _params = _params.copyWith(weld: val);
                _updateCyclogram();
              });
            },
            0.5,
            99.5,
          ),
          const SizedBox(height: 8),

          _buildParameterCard(
            'Мощность/ток сварки',
            'POWER',
            _params.power.toDouble(),
            (val) {
              setState(() {
                _params = _params.copyWith(power: val.toInt());
                _updateCyclogram();
              });
            },
            5,
            99,
          ),
          const SizedBox(height: 8),

          _buildParameterCard(
            'Число импульсов',
            'IMPULSE N.',
            _params.impulseN.toDouble(),
            (val) {
              setState(() {
                _params = _params.copyWith(impulseN: val.toInt());
                _updateCyclogram();
              });
            },
            1,
            9,
          ),
          const SizedBox(height: 8),

          _buildParameterCard(
            'Пауза 2 — между сварочными импульсами',
            'COLD 2',
            _params.cold2.toDouble(),
            (val) {
              setState(() {
                _params = _params.copyWith(cold2: val.toInt());
                _updateCyclogram();
              });
            },
            0,
            50,
          ),
          const SizedBox(height: 16),

          _buildParameterCard(
            'Время спада тока',
            'SLOPE DOWN',
            _params.slopeDown.toDouble(),
            (val) {
              setState(() {
                _params = _params.copyWith(slopeDown: val.toInt());
                _updateCyclogram();
              });
            },
            0,
            25,
          ),
          const SizedBox(height: 8),

          _buildParameterCard(
            'Пауза 3 — между сваркой и операцией после',
            'COLD 3',
            _params.cold3.toDouble(),
            (val) {
              setState(() {
                _params = _params.copyWith(cold3: val.toInt());
                _updateCyclogram();
              });
            },
            0,
            50,
          ),
          const SizedBox(height: 16),

          _buildParameterCard(
            'Время операции после сварки',
            'POST-WELD.',
            _params.postWeld,
            (val) {
              setState(() {
                _params = _params.copyWith(postWeld: val);
                _updateCyclogram();
              });
            },
            0,
            99.5,
          ),
          const SizedBox(height: 8),

          _buildParameterCard(
            'Мощность/ток после сварки',
            'POST-POWER',
            _params.postPower.toDouble(),
            (val) {
              setState(() {
                _params = _params.copyWith(postPower: val.toInt());
                _updateCyclogram();
              });
            },
            5,
            99,
          ),
          const SizedBox(height: 16),

          _buildParameterCard(
            'Время удержания усилия/давления',
            'HOLD TIME',
            _params.holdTime,
            (val) {
              setState(() {
                _params = _params.copyWith(holdTime: val);
                _updateCyclogram();
              });
            },
            0.5,
            99.5,
          ),
          const SizedBox(height: 8),

          _buildParameterCard(
            'Пауза между циклами',
            'OFF TIME',
            _params.offTime,
            (val) {
              setState(() {
                final rounded = val.roundToDouble();
                final clamped = rounded.clamp(minOffTime, 99.5);
                _params = _params.copyWith(offTime: clamped);
                _updateCyclogram();
              });
            },
            minOffTime,
            99.5,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ---- ИСХОДНЫЕ ДАННЫЕ ----
  Widget _buildMaterialDropdown() {
    final materials = ['АМг6'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: DropdownButtonFormField<String>(
          key: const Key('material_dropdown'),
          decoration: const InputDecoration(
            labelText: 'Материал',
            border: OutlineInputBorder(),
          ),
          value: _params.material,
          items: materials.map((m) {
            return DropdownMenuItem(value: m, child: Text(m));
          }).toList(),
          onChanged: (val) {
            setState(() {
              _params = _params.copyWith(material: val!);
              _updateCyclogram();
            });
          },
        ),
      ),
    );
  }

  Widget _buildCompactParameterField({
    required String label,
    required double value,
    required double min,
    required double max,
    required Function(double) onChanged,
    required TextEditingController controller,
    String? errorText,
    bool Function(String)? onValidate,
    double step = 0.1,
    bool isInt = false,
  }) {
    final displayValue = isInt 
        ? value.toInt().toString() 
        : value.toStringAsFixed(1).replaceFirst('.', ',');
    
    if (controller.text != displayValue && !controller.selection.isValid) {
      controller.text = displayValue;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Окошко слева
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(4),
                    ),
                    onChanged: (text) {
                      if (onValidate != null) {
                        final isValid = onValidate(text);
                        if (!isValid) return;
                      }
                      final normalized = text.replaceFirst(',', '.');
                      final newVal = double.tryParse(normalized);
                      if (newVal != null) {
                        if (isInt) {
                          final stepped = (newVal / step).roundToDouble() * step;
                          onChanged(stepped);
                        } else {
                          final rounded = (newVal * 10).round() / 10.0;
                          onChanged(rounded);
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Подпись сверху и ползунок
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (errorText != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            errorText,
                            style: const TextStyle(color: Colors.red, fontSize: 11),
                          ),
                        ),
                      Slider(
                        value: value.clamp(min, max),
                        min: min,
                        max: max,
                        divisions: isInt ? ((max - min) / step).toInt() : 100,
                        onChanged: onChanged,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNuggetField() {
    final calculated = ((3 * _params.thicknessTop + 2) * 0.9).ceilToDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Flexible(
              child: Text(
                'Диаметр точки, мм',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              calculated.toStringAsFixed(0),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // ---- РАСЧЁТНЫЕ ПАРАМЕТРЫ ----
  Widget _buildParameterCard(
    String label,
    String code,
    double value,
    Function(double) onChanged,
    double min,
    double max, {
    String subtitle = '',
    Key? inputKey,
  }) {
    // Форматируем значение: ток и давление с одним знаком после запятой,
    // остальные параметры (время, импульсы) — целые числа
    final bool isCurrentOrPressure = code == 'POWER' || code == 'POST-POWER' || 
                                     code == 'PRESSURE' || code == 'FORG.PRESS.' ||
                                     code == 'PRE-POWER';
    final String formattedValue = isCurrentOrPressure 
        ? value.toStringAsFixed(1).replaceFirst('.', ',') 
        : value.round().toString();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    code,
                    style: const TextStyle(fontSize: 9),
                  ),
                ),
              ],
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: value,
                    min: min,
                    max: max,
                    divisions: isCurrentOrPressure ? 1000 : 100,
                    onChanged: onChanged,
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 50,
                  child: TextField(
                    key: inputKey,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(4),
                    ),
                    controller: TextEditingController(
                      text: formattedValue,
                    ),
                    onChanged: (text) {
                      final normalized = text.replaceFirst(',', '.');
                      final newValue = double.tryParse(normalized);
                      if (newValue != null && newValue >= min && newValue <= max) {
                        if (isCurrentOrPressure) {
                          final rounded = (newValue * 10).round() / 10.0;
                          onChanged(rounded);
                        } else {
                          final rounded = newValue.roundToDouble();
                          onChanged(rounded);
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ГРАФИК ====================
  Widget _buildChartView() {
    final currentSpots = _cyclogramData['current'] ?? [];
    final forceSpots = _cyclogramData['force'] ?? [];

    if (currentSpots.isEmpty || forceSpots.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('Нет данных для построения графика'),
          ],
        ),
      );
    }

    // Масштабирование давления для правой шкалы (0–6 бар → 0–100)
    final scaledForceSpots = forceSpots.map((s) => FlSpot(s.x, s.y * 10)).toList();

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Циклограмма сварки', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Всего импульсов: ${_calculateTotalCycleTime().toStringAsFixed(0)}'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: _calculateMaxTime(currentSpots, forceSpots),
                  minY: 0,
                  maxY: 100,
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 10,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toStringAsFixed(0));
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 10,
                        getTitlesWidget: (value, meta) {
                          final barValue = (value / 10).roundToDouble();
                          return Text(barValue.toStringAsFixed(0));
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value == value.toInt()) {
                            return Text(value.toInt().toString());
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: currentSpots,
                      isCurved: false,
                      color: Colors.blue,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.2),
                      ),
                      dotData: FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: scaledForceSpots,
                      isCurved: false,
                      color: Colors.red,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                  lineTouchData: const LineTouchData(enabled: false),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendItem(Colors.blue, 'Ток, %'),
                const SizedBox(width: 24),
                _legendItem(Colors.red, 'Давление, бар'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) => Row(
        children: [
          Container(width: 20, height: 3, color: color),
          const SizedBox(width: 8),
          Text(label),
        ],
      );

  // ==================== ВСПОМОГАТЕЛЬНЫЕ ====================
  double _calculateMaxTime(List<FlSpot> current, List<FlSpot> force) {
    double max = 0;
    for (var s in current) if (s.x > max) max = s.x;
    for (var s in force) if (s.x > max) max = s.x;
    return max + 2;
  }

  // ==================== РАСЧЁТ ОБЩЕГО ВРЕМЕНИ ЦИКЛА ====================
  double _calculateTotalCycleTime() {
    final maxPressure = _params.forgePressure > _params.pressure 
        ? _params.forgePressure 
        : _params.pressure;
    final decayTime = maxPressure / 0.3;

    // Базовая длительность цикла без учёта offTime
    double baseTime = _params.squeeze1 +
        _params.weld +
        _params.cold3 +
        _params.postWeld +
        _params.holdTime +
        _params.slopeUp +
        _params.slopeDown;

    // Эффективное offTime — всегда >= времени спада
    final effectiveOffTime = _params.offTime < decayTime ? decayTime : _params.offTime;

    return baseTime + effectiveOffTime;
  }

  // ==================== ГЕНЕРАЦИЯ ЦИКЛОГРАММЫ ====================
  Map<String, List<FlSpot>> _generateCyclogramData() {
    List<FlSpot> currentSpots = [];
    List<FlSpot> forceSpots = [];

    final pressureValue = _params.pressure;
    final forgePressureValue = _params.forgePressure;
    final squeeze1 = _params.squeeze1;
    final isForgeActive = (_params.forgeDelay > 0 && _params.forgePressure > 0);

    final pRate = MachineSpecs.pressureRiseRate;
    final vElectrode = MachineSpecs.electrodeVelocity;

    final tTouch = _params.stroke / vElectrode;
    final tPressureRise = pressureValue / pRate;
    final tSqueeze = squeeze1;
    final tWeldStart = squeeze1;
    final tWeldEnd = tWeldStart + _params.weld;
    final tSlopeDown = _params.slopeDown;
    final tCold3 = tWeldEnd + (tSlopeDown > 0 ? tSlopeDown : 0) + _params.cold3;
    final tPostWeldStart = tCold3;
    final tPostWeldEnd = tPostWeldStart + _params.postWeld;

    final tForgeRise = (forgePressureValue - pressureValue) / pRate;
    final tDecay = (isForgeActive ? forgePressureValue : pressureValue) / pRate;

    final tForgeStart = squeeze1 + _params.forgeDelay;
    final tForgeEnd = tForgeStart + tForgeRise;
    final tHoldStart = tPostWeldEnd;
    final holdTime = _params.holdTime > 0 ? _params.holdTime : 1.0;
    final tHoldEnd = tHoldStart + holdTime;
    final tDecayEnd = tHoldEnd + tDecay;

    // Расчёт времени спада давления
    final maxPressure = _params.forgePressure > _params.pressure 
        ? _params.forgePressure 
        : _params.pressure;
    final decayTime = maxPressure / 0.3;

    // Эффективное offTime — всегда >= времени спада
    final effectiveOffTime = _params.offTime < decayTime ? decayTime : _params.offTime;
    // Дополнительная пауза (горизонтальный отрезок) — только если offTime > decayTime
    final extraPause = _params.offTime - decayTime;
    // Если offTime меньше или равно decayTime — extraPause = 0, отрезка нет
    final totalTime = tDecayEnd + extraPause;

    void addCurrentPoint(double time, double value) {
      currentSpots.add(FlSpot(time, value));
    }

    // ---- ФОРМИРОВАНИЕ ТОКА ----
    // Точка старта
    addCurrentPoint(0, 0);

    if (_params.preWeld > 0 && _params.prePower > 0) {
      final preWeldStart = tSqueeze;
      final preWeldEnd = preWeldStart + _params.preWeld;

      addCurrentPoint(preWeldStart, 0);
      addCurrentPoint(preWeldStart, _params.prePower.toDouble());

      addCurrentPoint(preWeldEnd, _params.prePower.toDouble());
      addCurrentPoint(preWeldEnd, 0);

      final cold1Start = preWeldEnd;
      final cold1End = cold1Start + _params.cold1;
      if (_params.cold1 > 0) {
        addCurrentPoint(cold1Start, 0);
        addCurrentPoint(cold1End, 0);
      }
    }

    addCurrentPoint(tWeldStart, 0);
    addCurrentPoint(tWeldStart, _params.power.toDouble());

    addCurrentPoint(tWeldEnd, _params.power.toDouble());
    addCurrentPoint(tWeldEnd, 0);

    final cold3Start = tWeldEnd;
    final cold3End = cold3Start + _params.cold3;
    addCurrentPoint(cold3Start, 0);
    addCurrentPoint(cold3End, 0);

    if (_params.postWeld > 0 && _params.postPower > 0) {
      addCurrentPoint(tPostWeldStart, 0);
      addCurrentPoint(tPostWeldStart, _params.postPower.toDouble());

      addCurrentPoint(tPostWeldEnd, _params.postPower.toDouble());
      addCurrentPoint(tPostWeldEnd, 0);
    }

    addCurrentPoint(tHoldStart, 0);
    addCurrentPoint(tHoldEnd, 0);
    addCurrentPoint(tDecayEnd, 0);
    addCurrentPoint(totalTime, 0);

    // ---- ФОРМИРОВАНИЕ УСИЛИЯ ----
    void addForcePoint(double time, double value) {
      forceSpots.add(FlSpot(time, value));
    }

    addForcePoint(0, 0);

    final steps = 10;
    for (int i = 0; i <= steps; i++) {
      final fraction = i / steps;
      final t = tTouch + tPressureRise * fraction;
      final rawValue = pressureValue * fraction;
      addForcePoint(t, rawValue);
    }
    addForcePoint(tSqueeze, pressureValue);

    if (!isForgeActive) {
      // Спад давления от PRESSURE до 0
      addForcePoint(tHoldStart, pressureValue);
      addForcePoint(tHoldEnd, pressureValue);
      for (int i = 0; i <= steps; i++) {
        final fraction = i / steps;
        final t = tHoldEnd + tDecay * fraction;
        final rawValue = pressureValue * (1 - fraction);
        addForcePoint(t, rawValue);
      }
      addForcePoint(tDecayEnd, 0);
    } else {
      // Рост до FORG.PRESS., затем спад до 0
      addForcePoint(tForgeStart, pressureValue);
      for (int i = 0; i <= steps; i++) {
        final fraction = i / steps;
        final t = tForgeStart + tForgeRise * fraction;
        final rawValue = pressureValue + (forgePressureValue - pressureValue) * fraction;
        addForcePoint(t, rawValue);
      }
      addForcePoint(tForgeEnd, forgePressureValue);
      addForcePoint(tHoldStart, forgePressureValue);
      addForcePoint(tHoldEnd, forgePressureValue);
      for (int i = 0; i <= steps; i++) {
        final fraction = i / steps;
        final t = tHoldEnd + tDecay * fraction;
        final rawValue = forgePressureValue * (1 - fraction);
        addForcePoint(t, rawValue);
      }
      addForcePoint(tDecayEnd, 0);
    }

    // Если extraPause > 0 — добавляем горизонтальный отрезок
    addForcePoint(totalTime, 0);

    return {
      'current': currentSpots,
      'force': forceSpots,
    };
  }
}