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
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // ==================== СОСТОЯНИЕ ====================
  late WeldingParameters _params;
  Map<String, List<FlSpot>> _cyclogramData = {};
  int _selectedTab = 0;

  // ==================== ЖИЗНЕННЫЙ ЦИКЛ ====================
  @override
  void initState() {
    super.initState();
    _params = WeldingParameters.defaults();
    _updateCyclogram();
  }

  void _updateCyclogram() {
    setState(() {
      _cyclogramData = _generateCyclogramData();
    });
  }

  // ==================== ДЕЙСТВИЯ ====================
  void _resetParameters() {
    setState(() {
      _params = WeldingParameters.defaults();
      _updateCyclogram();
    });
  }

  void _applyCalculatedParameters(CalculatedParameters result) {
    setState(() {
      _params = _params.copyWith(
        power: result.power.toInt().clamp(5, 99),
        weld: result.weld.clamp(0.5, 99.5),
        pressure: result.pressure.clamp(0.5, 10.0),
        squeeze1: result.squeeze1.clamp(0.5, 99.5),
        forgePressure: result.forgePressure.clamp(0, 10.0),
        forgeDelay: result.forgeDelay.toInt().clamp(0, 99),
        cold3: result.cold3.toInt().clamp(0, 50),
        postWeld: result.postWeld.clamp(0, 99.5),
        postPower: result.postPower.toInt().clamp(5, 99),
        holdTime: result.holdTime.clamp(0.5, 99.5),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ---- ИСХОДНЫЕ ДАННЫЕ ----
          _buildMaterialDropdown(),
          const SizedBox(height: 16),

          _buildThicknessField(
            label: 'Толщина верхней детали (меньшая), мм',
            value: _params.thicknessTop,
            onChanged: (val) {
              // Округляем до одного знака после запятой
              final rounded = (val * 10).round() / 10.0;
              setState(() {
                final newVal = rounded.clamp(0.3, _params.thicknessBottom);
                _params = _params.copyWith(
                  thicknessTop: newVal,
                  thicknessBottom: _params.thicknessBottom,
                );
                _updateCyclogram();
              });
            },
            min: 0.3,
            max: _params.thicknessBottom,
          ),
          const SizedBox(height: 8),

          _buildThicknessField(
            label: 'Толщина нижней детали (большая), мм',
            value: _params.thicknessBottom,
            onChanged: (val) {
              // Округляем до одного знака после запятой
              final rounded = (val * 10).round() / 10.0;
              setState(() {
                final newVal = rounded.clamp(_params.thicknessTop, 3.0);
                _params = _params.copyWith(
                  thicknessBottom: newVal,
                  thicknessTop: _params.thicknessTop,
                );
                _updateCyclogram();
              });
            },
            min: _params.thicknessTop,
            max: 3.0,
          ),
          const SizedBox(height: 8),

          _buildStrokeField(),
          const SizedBox(height: 8),

          _buildNuggetField(),
          const SizedBox(height: 16),

          // ---- КНОПКА РАССЧИТАТЬ ----
          ElevatedButton(
            onPressed: () {
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
              backgroundColor: Colors.green.shade700,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text(
              'Рассчитать',
              style: TextStyle(fontSize: 16, color: Colors.white),
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
                _params = _params.copyWith(offTime: val);
                _updateCyclogram();
              });
            },
            0,
            99.5,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ---- ИСХОДНЫЕ ДАННЫЕ ----
  Widget _buildMaterialDropdown() {
    final materials = ['АМг6', 'Сталь 20', 'Алюминий АД1'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: DropdownButtonFormField<String>(
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

  Widget _buildThicknessField({
    required String label,
    required double value,
    required Function(double) onChanged,
    required double min,
    required double max,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 80,
              child: TextField(
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(4),
                ),
                controller: TextEditingController(
                  text: value.toStringAsFixed(1).replaceFirst('.', ','),
                ),
                onChanged: (text) {
                  final normalized = text.replaceFirst(',', '.');
                  final newVal = double.tryParse(normalized);
                  if (newVal != null && newVal >= min && newVal <= max) {
                    // Округляем до одного знака после запятой
                    final rounded = (newVal * 10).round() / 10.0;
                    onChanged(rounded);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: 50,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrokeField() {
    final value = _params.stroke;
    const minValue = 5.0;
    const maxValue = 50.0;
    const step = 5.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Рабочий ход электродов, мм',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 80,
              child: TextField(
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(4),
                ),
                controller: TextEditingController(
                  text: value.toInt().toString(),
                ),
                onChanged: (text) {
                  final newVal = double.tryParse(text);
                  if (newVal != null && newVal >= minValue && newVal <= maxValue) {
                    final stepped = (newVal / step).roundToDouble() * step;
                    setState(() {
                      _params = _params.copyWith(stroke: stepped);
                      _updateCyclogram();
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Slider(
                value: value,
                min: minValue,
                max: maxValue,
                divisions: ((maxValue - minValue) / step).toInt(),
                onChanged: (val) {
                  final stepped = (val / step).roundToDouble() * step;
                  setState(() {
                    _params = _params.copyWith(stroke: stepped);
                    _updateCyclogram();
                  });
                },
              ),
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
            const Expanded(
              child: Text(
                'Диаметр точки, мм',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              calculated.toStringAsFixed(0),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
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
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(code, style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: value,
                    min: min,
                    max: max,
                    divisions: 100,
                    onChanged: onChanged,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 60,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(4),
                    ),
                    controller: TextEditingController(
                      text: value.toStringAsFixed(1).replaceFirst('.', ','),
                    ),
                    onChanged: (text) {
                      final normalized = text.replaceFirst(',', '.');
                      final newValue = double.tryParse(normalized);
                      if (newValue != null && newValue >= min && newValue <= max) {
                        // Округляем до одного знака после запятой
                        final rounded = (newValue * 10).round() / 10.0;
                        onChanged(rounded);
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

    // Масштабирование давления для правой шкалы (0–10 бар → 0–100)
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
                          return Text('${value.toInt()}%');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 10,
                        getTitlesWidget: (value, meta) {
                          final barValue = (value / 100 * 10).roundToDouble();
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
                ),
              ),
            ),
          ),
          // Легенда
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
    final pressureValue = _params.pressure;
    final forgePressureValue = _params.forgePressure;
    final squeeze1 = _params.squeeze1;
    final isForgeActive = (_params.forgeDelay > 0 && _params.forgePressure > 0);
    
    double weldEndTime = squeeze1;
    if (_params.preWeld > 0) weldEndTime += _params.preWeld + _params.cold1;
    weldEndTime += _params.slopeUp;
    for (int i = 0; i < _params.impulseN; i++) {
      weldEndTime += _params.weld;
      if (i < _params.impulseN - 1) weldEndTime += _params.cold2;
    }
    weldEndTime += _params.slopeDown + _params.cold3;
    if (_params.postWeld > 0) weldEndTime += _params.postWeld;
    
    final holdEndTime = weldEndTime + _params.holdTime;
    
    double pressureEndTime;
    if (!isForgeActive) {
      pressureEndTime = holdEndTime + pressureValue;
    } else {
      pressureEndTime = holdEndTime + forgePressureValue;
    }
    
    pressureEndTime += _params.offTime;
    return pressureEndTime;
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

    // ---- 1. ВСПОМОГАТЕЛЬНЫЕ ВРЕМЕННЫЕ ТОЧКИ ----
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
    final tHoldEnd = tHoldStart + _params.holdTime;
    final tDecayEnd = tHoldEnd + tDecay;
    final totalTime = tDecayEnd + _params.offTime;

    // ---- 2. ГЕНЕРАЦИЯ ТОЧЕК ТОКА ----
    void addCurrentPoint(double time, double value) {
      currentSpots.add(FlSpot(time, value));
    }

    // Начало
    addCurrentPoint(0, 0);

    // PRE-WELD (если есть)
    if (_params.preWeld > 0 && _params.prePower > 0) {
      final preWeldStart = tSqueeze;
      final preWeldEnd = preWeldStart + _params.preWeld;
      
      // Начало PRE-WELD: 0 → PRE-POWER
      addCurrentPoint(preWeldStart, 0);
      addCurrentPoint(preWeldStart, _params.prePower.toDouble());
      
      // Конец PRE-WELD: PRE-POWER → 0
      addCurrentPoint(preWeldEnd, _params.prePower.toDouble());
      addCurrentPoint(preWeldEnd, 0);
      
      // COLD 1
      final cold1Start = preWeldEnd;
      final cold1End = cold1Start + _params.cold1;
      if (_params.cold1 > 0) {
        addCurrentPoint(cold1Start, 0);
        addCurrentPoint(cold1End, 0);
      }
    }

    // Начало WELD: 0 → POWER
    addCurrentPoint(tWeldStart, 0);
    addCurrentPoint(tWeldStart, _params.power.toDouble());

    // Конец WELD: POWER → 0
    addCurrentPoint(tWeldEnd, _params.power.toDouble());
    addCurrentPoint(tWeldEnd, 0);

    // COLD 3
    final cold3Start = tWeldEnd;
    final cold3End = cold3Start + _params.cold3;
    addCurrentPoint(cold3Start, 0);
    addCurrentPoint(cold3End, 0);

    // POST-WELD (если есть)
    if (_params.postWeld > 0 && _params.postPower > 0) {
      // Начало POST-WELD: 0 → POST-POWER
      addCurrentPoint(tPostWeldStart, 0);
      addCurrentPoint(tPostWeldStart, _params.postPower.toDouble());
      
      // Конец POST-WELD: POST-POWER → 0
      addCurrentPoint(tPostWeldEnd, _params.postPower.toDouble());
      addCurrentPoint(tPostWeldEnd, 0);
    }

    // Остальные точки (ток уже 0)
    addCurrentPoint(tHoldStart, 0);
    addCurrentPoint(tHoldEnd, 0);
    addCurrentPoint(tDecayEnd, 0);
    addCurrentPoint(totalTime, 0);

    // ---- 3. ГЕНЕРАЦИЯ ТОЧЕК ДАВЛЕНИЯ ----
    void addForcePoint(double time, double value) {
      forceSpots.add(FlSpot(time, value));
    }

    addForcePoint(0, 0);

    // Подъём давления от 0 до PRESSURE
    final steps = 10;
    for (int i = 0; i <= steps; i++) {
      final fraction = i / steps;
      final t = tTouch + tPressureRise * fraction;
      final value = pressureValue * fraction;
      addForcePoint(t, value);
    }
    addForcePoint(tSqueeze, pressureValue);

    if (!isForgeActive) {
      // Без ковки
      addForcePoint(tHoldStart, pressureValue);
      for (int i = 0; i <= steps; i++) {
        final fraction = i / steps;
        final t = tHoldStart + tDecay * fraction;
        final value = pressureValue * (1 - fraction);
        addForcePoint(t, value);
      }
      addForcePoint(tDecayEnd, 0);
    } else {
      // С ковкой
      addForcePoint(tForgeStart, pressureValue);
      for (int i = 0; i <= steps; i++) {
        final fraction = i / steps;
        final t = tForgeStart + tForgeRise * fraction;
        final value = pressureValue + (forgePressureValue - pressureValue) * fraction;
        addForcePoint(t, value);
      }
      addForcePoint(tForgeEnd, forgePressureValue);
      addForcePoint(tHoldStart, forgePressureValue);
      for (int i = 0; i <= steps; i++) {
        final fraction = i / steps;
        final t = tHoldStart + tDecay * fraction;
        final value = forgePressureValue * (1 - fraction);
        addForcePoint(t, value);
      }
      addForcePoint(tDecayEnd, 0);
    }

    addForcePoint(totalTime, 0);

    return {
      'current': currentSpots,
      'force': forceSpots,
    };
  }
}