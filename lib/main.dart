// ============================================================
// main.dart
// RSW svarcOS — главный экран приложения
// ============================================================

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'data/models/welding_parameters.dart';
import 'data/models/calculated_parameters.dart';
import 'domain/usecases/calculate_parameters_usecase.dart';

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
      // PRESSURE (сварочное давление)
      final pressure = result.weldingForce;

      // FORG.PRESS. (давление проковки) — должно быть >= PRESSURE
      final forgePressure = result.forgeTime > 0 
          ? result.weldingForce * 1.5 
          : result.weldingForce;

      // WELD TIME — уже в циклах, берём как есть
      final weldCycles = result.weldingTime;

      // FORGE DELAY — уже в циклах, берём как есть
      final forgeDelayCycles = result.forgeTime;

      _params = _params.copyWith(
        pressure: pressure,
        forgePressure: forgePressure,
        weld: weldCycles.clamp(0.5, 99.5),
        forgeDelay: forgeDelayCycles.toInt().clamp(0, 99),
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
              setState(() {
                final newVal = val.clamp(1.0, _params.thicknessBottom);
                _params = _params.copyWith(
                  thicknessTop: newVal,
                  thicknessBottom: _params.thicknessBottom,
                );
                _updateCyclogram();
              });
            },
            min: 1.0,
            max: _params.thicknessBottom,
          ),
          const SizedBox(height: 8),

          _buildThicknessField(
            label: 'Толщина нижней детали (большая), мм',
            value: _params.thicknessBottom,
            onChanged: (val) {
              setState(() {
                final newVal = val.clamp(_params.thicknessTop, 4.0);
                _params = _params.copyWith(
                  thicknessBottom: newVal,
                  thicknessTop: _params.thicknessTop,
                );
                _updateCyclogram();
              });
            },
            min: _params.thicknessTop,
            max: 4.0,
          ),
          const SizedBox(height: 8),

          _buildNuggetField(),
          const SizedBox(height: 16),

          // ---- КНОПКА РАССЧИТАТЬ ----
          ElevatedButton(
            onPressed: () {
              try {
                final useCase = CalculateParametersUseCase();
                final result = useCase(
                  materialName: _params.material,
                  thickness: _params.thicknessTop,
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
            'Пауза 2 — между импульсами',
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
            'Пауза 3 — между сваркой и термообработкой',
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
            'Время отпуска',
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
            'Мощность/ток отпуска',
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
            'Время удержания',
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
    final materials = ['АМг6', 'Сталь 08кп', 'Сталь 20', 'Алюминий АД1'];
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
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                controller: TextEditingController(text: value.toStringAsFixed(1)),
                onChanged: (text) {
                  final newVal = double.tryParse(text);
                  if (newVal != null && newVal >= min && newVal <= max) {
                    onChanged(newVal);
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
                divisions: 30,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNuggetField() {
    // Расчёт по ГОСТ 15878-79: d = 1.75 + 2.5 * s
    // Округление вверх до целого (шаг 1 мм)
    final calculated = (1.75 + 2.5 * _params.thicknessTop).ceilToDouble();
    final currentValue = _params.nuggetDiameter;

    // Диапазон: от расчётного до 12 мм (шаг 1 мм)
    final minValue = calculated.clamp(4.0, 12.0);
    const maxValue = 12.0;

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
                  text: currentValue.toStringAsFixed(0).replaceFirst('.', ','),
                ),
                onChanged: (text) {
                  final normalized = text.replaceFirst(',', '.');
                  final newVal = double.tryParse(normalized);
                  if (newVal != null && newVal >= minValue && newVal <= maxValue) {
                    setState(() {
                      _params = _params.copyWith(nuggetDiameter: newVal);
                      _updateCyclogram();
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Slider(
                value: currentValue.clamp(minValue, maxValue),
                min: minValue,
                max: maxValue,
                divisions: 8,
                onChanged: (val) {
                  setState(() {
                    _params = _params.copyWith(nuggetDiameter: val);
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
                    controller: TextEditingController(text: value.toStringAsFixed(1)),
                    onChanged: (text) {
                      final newValue = double.tryParse(text);
                      if (newValue != null && newValue >= min && newValue <= max) {
                        onChanged(newValue);
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
                  child: Text('Всего циклов: ${_calculateTotalCycleTime().toStringAsFixed(0)}'),
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
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}%');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
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
                      spots: forceSpots.map((s) => FlSpot(s.x, s.y * 10)).toList(),
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
    final totalCycleTime = _calculateTotalCycleTime();
    final pressureValue = _params.pressure;
    final forgePressureValue = _params.forgePressure;
    final squeeze1 = _params.squeeze1;

    final timeToReachPressure = 10 + pressureValue;
    
    double weldEndTime = squeeze1;
    if (_params.preWeld > 0) weldEndTime += _params.preWeld + _params.cold1;
    weldEndTime += _params.slopeUp;
    for (int i = 0; i < _params.impulseN; i++) {
      weldEndTime += _params.weld;
      if (i < _params.impulseN - 1) weldEndTime += _params.cold2;
    }
    weldEndTime += _params.slopeDown + _params.cold3;
    if (_params.postWeld > 0) weldEndTime += _params.postWeld;
    
    final forgeEndTime = squeeze1 + _params.forgeDelay;
    final holdEndTime = weldEndTime + _params.holdTime;
    final isForgeActive = (_params.forgeDelay > 0 && _params.forgePressure > 0);
    final forgeRiseEndTime = forgeEndTime + forgePressureValue;
    final decayEndTime = holdEndTime + (isForgeActive ? forgePressureValue : pressureValue);
    final finalTime = decayEndTime + _params.offTime;

    // ---- ФУНКЦИЯ РАСЧЁТА ТОКА ----
    List<FlSpot> calculateCurrentSpots() {
      List<FlSpot> spots = [];
      
      spots.add(FlSpot(0, 0));
      spots.add(FlSpot(squeeze1, 0));
      
      double currentTime = squeeze1;
      
      if (_params.preWeld > 0 && _params.prePower > 0) {
        final prePower = _params.prePower.toDouble();
        spots.add(FlSpot(currentTime, prePower));
        currentTime += _params.preWeld;
        spots.add(FlSpot(currentTime, prePower));
        spots.add(FlSpot(currentTime, 0));
        
        currentTime += _params.cold1;
        spots.add(FlSpot(currentTime, 0));
      }
      
      final powerValue = _params.power.toDouble();
      for (int i = 0; i < _params.impulseN; i++) {
        if (_params.slopeUp > 0) {
          final slopeStart = currentTime;
          final slopeEnd = currentTime + _params.slopeUp;
          final steps = 10;
          for (int j = 0; j <= steps; j++) {
            final fraction = j / steps;
            final t = slopeStart + _params.slopeUp * fraction;
            final value = powerValue * fraction;
            spots.add(FlSpot(t, value));
          }
          currentTime = slopeEnd;
        } else {
          spots.add(FlSpot(currentTime, powerValue));
        }
        
        final weldStart = currentTime;
        final weldEnd = currentTime + _params.weld;
        spots.add(FlSpot(weldStart, powerValue));
        spots.add(FlSpot(weldEnd, powerValue));
        currentTime = weldEnd;
        
        if (i < _params.impulseN - 1) {
          spots.add(FlSpot(currentTime, 0));
          currentTime += _params.cold2;
          spots.add(FlSpot(currentTime, 0));
        }
      }
      
      if (_params.slopeDown > 0) {
        final slopeStart = currentTime;
        final slopeEnd = currentTime + _params.slopeDown;
        final steps = 10;
        for (int j = 0; j <= steps; j++) {
          final fraction = j / steps;
          final t = slopeStart + _params.slopeDown * fraction;
          final value = powerValue * (1 - fraction);
          spots.add(FlSpot(t, value));
        }
        currentTime = slopeEnd;
      } else {
        spots.add(FlSpot(currentTime, 0));
      }
      
      currentTime += _params.cold3;
      spots.add(FlSpot(currentTime, 0));
      
      if (_params.postWeld > 0 && _params.postPower > 0) {
        final postPower = _params.postPower.toDouble();
        spots.add(FlSpot(currentTime, postPower));
        currentTime += _params.postWeld;
        spots.add(FlSpot(currentTime, postPower));
        spots.add(FlSpot(currentTime, 0));
      }
      
      spots.add(FlSpot(finalTime, 0));
      return spots;
    }

    // ---- ФУНКЦИЯ РАСЧЁТА УСИЛИЯ ----
    List<FlSpot> calculateForceSpots() {
      List<FlSpot> spots = [];
      
      spots.add(FlSpot(0, 0));
      spots.add(FlSpot(10, 0));
      
      final steps = 10;
      for (int i = 0; i <= steps; i++) {
        final fraction = i / steps;
        final t = 10 + (timeToReachPressure - 10) * fraction;
        final value = pressureValue * fraction;
        spots.add(FlSpot(t, value));
      }
      
      spots.add(FlSpot(timeToReachPressure, pressureValue));
      spots.add(FlSpot(squeeze1, pressureValue));
      
      if (!isForgeActive) {
        spots.add(FlSpot(holdEndTime, pressureValue));
        
        for (int i = 0; i <= steps; i++) {
          final fraction = i / steps;
          final t = holdEndTime + pressureValue * fraction;
          final value = pressureValue * (1 - fraction);
          spots.add(FlSpot(t, value));
        }
        spots.add(FlSpot(decayEndTime, 0));
      } else {
        spots.add(FlSpot(forgeEndTime, pressureValue));
        
        for (int i = 0; i <= steps; i++) {
          final fraction = i / steps;
          final t = forgeEndTime + forgePressureValue * fraction;
          final value = pressureValue + (forgePressureValue - pressureValue) * fraction;
          spots.add(FlSpot(t, value));
        }
        spots.add(FlSpot(forgeRiseEndTime, forgePressureValue));
        spots.add(FlSpot(holdEndTime, forgePressureValue));
        
        for (int i = 0; i <= steps; i++) {
          final fraction = i / steps;
          final t = holdEndTime + forgePressureValue * fraction;
          final value = forgePressureValue * (1 - fraction);
          spots.add(FlSpot(t, value));
        }
        spots.add(FlSpot(decayEndTime, 0));
      }
      
      spots.add(FlSpot(finalTime, 0));
      return spots;
    }

    List<FlSpot> currentSpots = calculateCurrentSpots();
    List<FlSpot> forceSpots = calculateForceSpots();

    return {
      'current': currentSpots,
      'force': forceSpots,
    };
  }
}