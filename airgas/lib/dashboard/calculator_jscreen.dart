import 'dart:async'; // For Timer functionality
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For number formatting

/// Gas properties for conversion (SCF, Gallons, Pounds).

class GasConstants {
  final double scfPerGal;
  final double lbPerGal;
  final double scfPerLb;

  const GasConstants({
    required this.scfPerGal,
    required this.lbPerGal,
    required this.scfPerLb,
  });

  static const Map<String, GasConstants> gases = {
    'LIN': GasConstants(scfPerGal: 93.1, lbPerGal: 6.74, scfPerLb: 13.8),
    'LOX': GasConstants(scfPerGal: 115.0, lbPerGal: 9.52, scfPerLb: 12.06),
    'LAR': GasConstants(scfPerGal: 87.3, lbPerGal: 9.4, scfPerLb: 9.3),
  };
}

class CalculationResult {
  final double totalScf;
  final double totalGallons;
  final double poundsFromGallons;
  final double poundsFromScf;
  final String source;
  final String modeLabel;
  final double? diameterUsed;
  final String? estNote;
  final double? scfPerInch;
  final double? scfInches;
  final double? scfTimer;
  final double? elapsedMinutes;
  final double? flowGpm;
  final double? flowLbpm;
  final GasConstants gas; // Gas constants used for this calculation

  CalculationResult({
    required this.totalScf,
    required this.totalGallons,
    required this.poundsFromGallons,
    required this.poundsFromScf,
    required this.source,
    required this.gas,
    this.modeLabel = "",
    this.diameterUsed,
    this.estNote,
    this.scfPerInch,
    this.scfInches,
    this.scfTimer,
    this.elapsedMinutes,
    this.flowGpm,
    this.flowLbpm,
  });
}

// --- 2. CORE CALCULATION LOGIC ---

class CryoCalculatorLogic {
  final GasConstants gas;

  CryoCalculatorLogic(String gasKey)
    : gas = GasConstants.gases[gasKey] ?? GasConstants.gases['LIN']!;

  /// Calculates the area fractional fill of a horizontal cylinder.
  double _horizontalFraction(double d, double h) {
    final R = d / 2;
    if (d <= 0 || !h.isFinite) return 0.0;
    if (h <= 0) return 0.0;
    if (h >= d) return 1.0;

    final R_minus_h = R - h;
    final ratio = min(1.0, max(-1.0, R_minus_h / R));
    final a = acos(ratio);
    final Aseg = R * R * a - R_minus_h * sqrt(max(0.0, 2 * R * h - h * h));

    return Aseg / (pi * R * R);
  }

  /// Estimates the optimal cylinder diameter based on changes in inches and delivered SCF.
  double? _estimateDiameterFromTimer(
    double fullSCF,
    double start,
    double end,
    double scfDelivered, {
    double dMin = 60,
    double dMax = 130,
    double step = 0.1,
  }) {
    if (fullSCF == 0 || (end - start).abs() < 0.1 || scfDelivered == 0) {
      return null;
    }

    double bestD = dMin;
    double bestErr = double.infinity;

    for (double d = dMin; d <= dMax; d += step) {
      final pred =
          fullSCF *
          (_horizontalFraction(d, end) - _horizontalFraction(d, start));
      final err = (pred - scfDelivered).abs();

      if (err < bestErr) {
        bestErr = err;
        bestD = d;
      }
    }
    return bestD;
  }

  /// Adjusts elapsed time for a "dead time" (10-30 seconds, or 5% of duration) for laydown tanks.
  double? _adjustedElapsedMin(double? rawMin) {
    if (rawMin == null || rawMin <= 0) return null;
    final deadSec = min(30.0, max(10.0, rawMin * 60.0 * 0.05));
    return max(0.0, rawMin - deadSec / 60.0);
  }

  CalculationResult calculate({
    required String tankType,
    required double fullCapacity,
    required String capUnit,
    double? fullInches,
    double? startInches,
    double? endInches,
    double? geoDiameter,
    double? flowValue,
    bool isLbMode = false,
    int? elapsedMilliseconds,
    bool wantEstimateD = false,
    bool useTimerPrimary = false,
  }) {
    final gasUsed = gas;

    final fullSCF = capUnit == 'gal'
        ? fullCapacity * gasUsed.scfPerGal
        : fullCapacity;

    final elapsedMinRaw = elapsedMilliseconds != null
        ? elapsedMilliseconds / 1000.0 / 60.0
        : null;
    final elapsedMin = (tankType == 'laydown')
        ? _adjustedElapsedMin(elapsedMinRaw)
        : elapsedMinRaw;

    final flowGPM = flowValue != null
        ? (isLbMode ? flowValue / gasUsed.lbPerGal : flowValue)
        : null;
    final flowScfMin = flowGPM != null ? flowGPM * gasUsed.scfPerGal : null;
    final scfTimer = (elapsedMin != null && flowScfMin != null)
        ? flowScfMin * elapsedMin
        : null;

    // Fallback/Flow-Only Estimate (used if no inches are available)
    if ((startInches == null || endInches == null) && scfTimer != null) {
      return CalculationResult(
        totalScf: scfTimer,
        totalGallons: scfTimer / gasUsed.scfPerGal,
        poundsFromGallons: (scfTimer / gasUsed.scfPerGal) * gasUsed.lbPerGal,
        poundsFromScf: scfTimer / gasUsed.scfPerLb,
        source: "Flow-Only Estimate",
        gas: gasUsed,
        elapsedMinutes: elapsedMin,
        flowGpm: flowGPM,
        flowLbpm: flowGPM != null ? flowGPM * gasUsed.lbPerGal : null,
      );
    }

    // Inches-based Calculation
    double? scfInches;
    double? diameterUsed;
    String? estNote;
    String modeLabel = "";
    double? scfPerInch;

    if (startInches != null && endInches != null && fullSCF > 0) {
      final start = fullInches != null
          ? startInches.clamp(0.0, fullInches)
          : max(0.0, startInches);
      final end = fullInches != null
          ? endInches.clamp(0.0, fullInches)
          : max(0.0, endInches);
      final dInches = end - start;

      if (tankType == 'laydown') {
        diameterUsed = geoDiameter;

        if (diameterUsed == null &&
            wantEstimateD &&
            scfTimer != null &&
            scfTimer > 0) {
          final estD = _estimateDiameterFromTimer(
            fullSCF,
            start,
            end,
            scfTimer,
          );
          if (estD != null) {
            diameterUsed = estD;
            estNote = " (estimated D: ${estD.toStringAsFixed(1)} in)";
          }
        }

        if (diameterUsed != null && diameterUsed > 0) {
          final fs = _horizontalFraction(diameterUsed, max(0.0, start));
          final fe = _horizontalFraction(diameterUsed, max(0.0, end));
          scfInches = fullSCF * (fe - fs);
          modeLabel = "Laydown Tank (geometry)";

          const eps = 0.01;
          final mid = (start + end) / 2;
          final df =
              (_horizontalFraction(diameterUsed, mid + eps) -
                  _horizontalFraction(diameterUsed, mid - eps)) /
              (2 * eps);
          scfPerInch = fullSCF * df;
        } else if (fullInches != null && fullInches > 0) {
          // Empirical linear fallback
          const linearFactor = 0.94;
          final spi = (fullSCF / fullInches) * linearFactor;
          scfInches = dInches * spi;
          modeLabel = "Laydown Tank (empirical linear)";
          scfPerInch = spi;
        }
      } else {
        // Vertical Tank (Linear)
        final denom = fullInches != null && fullInches > 0 ? fullInches : 1.0;
        final spi = fullSCF / denom;
        scfInches = dInches * spi;
        modeLabel = "Vertical Tank (linear)";
        scfPerInch = spi;
      }
    }

    // Final result selection
    double? totalScf;
    String source;

    if (useTimerPrimary && scfTimer != null) {
      totalScf = scfTimer;
      source = "Timer × Flow (primary)";
    } else if (scfInches != null) {
      totalScf = scfInches;
      source = (tankType == 'laydown' && diameterUsed != null)
          ? "Inches (geometry)"
          : "Inches (linear/fallback)";
    } else if (scfTimer != null) {
      totalScf = scfTimer;
      source = "Timer × Flow";
    } else {
      return CalculationResult(
        totalScf: 0,
        totalGallons: 0,
        poundsFromGallons: 0,
        poundsFromScf: 0,
        source: "Not enough data.",
        gas: gasUsed,
      );
    }

    final finalScf = totalScf ?? 0.0;
    final totalGallons = finalScf / gasUsed.scfPerGal;
    final poundsFromGallons = totalGallons * gasUsed.lbPerGal;
    final poundsFromScf = finalScf / gasUsed.scfPerLb;

    return CalculationResult(
      totalScf: finalScf,
      totalGallons: totalGallons,
      poundsFromGallons: poundsFromGallons,
      poundsFromScf: poundsFromScf,
      source: source,
      gas: gasUsed,
      modeLabel: modeLabel,
      diameterUsed: diameterUsed,
      estNote: estNote,
      scfPerInch: scfPerInch,
      scfInches: scfInches,
      scfTimer: scfTimer,
      elapsedMinutes: elapsedMin,
      flowGpm: flowGPM,
      flowLbpm: flowGPM != null ? flowGPM * gasUsed.lbPerGal : null,
    );
  }
}

// --- 3. FLUTTER APPLICATION SETUP ---

class CryoCalculatorApp extends StatelessWidget {
  const CryoCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cryo Tank Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A73E8)),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          fillColor: Colors.white,
          filled: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A73E8),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF1A73E8)),
        ),
      ),
      home: const GasCalculatorScreen(),
    );
  }
}

class GasCalculatorScreen extends StatefulWidget {
  const GasCalculatorScreen({super.key});

  @override
  State<GasCalculatorScreen> createState() => _GasCalculatorScreenState();
}

class _GasCalculatorScreenState extends State<GasCalculatorScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Data shared across panes
  double _lastCalculatedSCF = 0;

  // Timer State
  Duration _elapsed = Duration.zero;
  DateTime? _t0;
  DateTime? _t1;
  Timer? _timer;

  void _startTimer() {
    setState(() {
      _t0 = DateTime.now();
      _t1 = null;
      _elapsed = Duration.zero;
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
        if (_t1 == null && _t0 != null) {
          setState(() {
            _elapsed = DateTime.now().difference(_t0!);
          });
        }
      });
    });
  }

  void _stopTimer() {
    setState(() {
      if (_t0 != null && _t1 == null) {
        _t1 = DateTime.now();
        _elapsed = _t1!.difference(_t0!);
        _timer?.cancel();
        _timer = null;
      }
    });
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentPage == 0
              ? 'Cryo Tank Calculator'
              : _currentPage == 1
              ? 'Cryo Split Calculator'
              : 'Cryo Reserve Calculator',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentPage = index);
        },
        children: [
          _CalculatorPane(
            updateLastCalculatedSCF: (scf) =>
                setState(() => _lastCalculatedSCF = scf),
            startTimer: _startTimer,
            stopTimer: _stopTimer,
            elapsed: _elapsed,
            t0: _t0,
            t1: _t1,
            goToSplit: () => _goToPage(1),
          ),
          _SplitPane(
            lastCalculatedSCF: _lastCalculatedSCF,
            goToCalc: () => _goToPage(0),
            goToReserve: () => _goToPage(2),
          ),
          _ReservePane(goToCalc: () => _goToPage(0)),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Swipe left/right',
              style: TextStyle(fontSize: 12, color: Color(0xFF667085)),
            ),
            const SizedBox(width: 8),
            ...List.generate(3, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: index == _currentPage
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// --- 4. CALCULATOR PANE IMPLEMENTATION ---

class _CalculatorPane extends StatefulWidget {
  final ValueChanged<double> updateLastCalculatedSCF;
  final VoidCallback startTimer;
  final VoidCallback stopTimer;
  final Duration elapsed;
  final DateTime? t0;
  final DateTime? t1;
  final VoidCallback goToSplit;

  const _CalculatorPane({
    required this.updateLastCalculatedSCF,
    required this.startTimer,
    required this.stopTimer,
    required this.elapsed,
    this.t0,
    this.t1,
    required this.goToSplit,
  });

  @override
  State<_CalculatorPane> createState() => _CalculatorPaneState();
}

class _CalculatorPaneState extends State<_CalculatorPane> {
  String _tankType = 'vertical';
  String _gasKey = 'LIN';
  String _capUnit = 'scf';

  final TextEditingController _fullInchesController = TextEditingController();
  final TextEditingController _fullCapController = TextEditingController();
  final TextEditingController _startInchesController = TextEditingController();
  final TextEditingController _endInchesController = TextEditingController();
  final TextEditingController _flowValueController = TextEditingController();
  final TextEditingController _geoDiameterController = TextEditingController();
  final TextEditingController _geoLengthController = TextEditingController();

  bool _isLbMode = false;
  bool _chkEstimateD = false;
  bool _useTimerPrimary = false;

  CalculationResult? _result;

  void _clearForm() {
    setState(() {
      _tankType = 'vertical';
      _gasKey = 'LIN';
      _capUnit = 'scf';
      _fullInchesController.clear();
      _fullCapController.clear();
      _startInchesController.clear();
      _endInchesController.clear();
      _flowValueController.clear();
      _geoDiameterController.clear();
      _geoLengthController.clear();
      _isLbMode = false;
      _chkEstimateD = false;
      _useTimerPrimary = false;
      _result = null;
      widget.stopTimer();
      widget.updateLastCalculatedSCF(0);
    });
  }

  void _calculate() {
    final logic = CryoCalculatorLogic(_gasKey);

    final int? elapsedMs =
        (widget.t0 != null &&
            (widget.t1 != null || widget.elapsed > Duration.zero))
        ? (widget.t1 ?? DateTime.now()).difference(widget.t0!).inMilliseconds
        : null;

    final result = logic.calculate(
      tankType: _tankType,
      fullCapacity: double.tryParse(_fullCapController.text) ?? 0.0,
      capUnit: _capUnit,
      fullInches: double.tryParse(_fullInchesController.text),
      startInches: double.tryParse(_startInchesController.text),
      endInches: double.tryParse(_endInchesController.text),
      geoDiameter: double.tryParse(_geoDiameterController.text),
      flowValue: double.tryParse(_flowValueController.text),
      isLbMode: _isLbMode,
      elapsedMilliseconds: elapsedMs,
      wantEstimateD: _chkEstimateD,
      useTimerPrimary: _useTimerPrimary,
    );

    setState(() {
      _result = result;
      widget.updateLastCalculatedSCF(result.totalScf.roundToDouble());
    });
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = two(d.inHours);
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return "$h:$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    final bool isLaydown = _tankType == 'laydown';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Tip: For laydown tanks, Full Inches means the Full Trycock inches when the tank is at “full.” Horizontal Measure captures cylinder diameter and length only—it does not measure Full Trycock height.',
            style: TextStyle(color: Color(0xFF667085), fontSize: 12),
          ),
          const SizedBox(height: 12),

          // --- Tank Type ---
          _buildDropdown(
            label: 'Tank Type:',
            value: _tankType,
            items: const ['vertical', 'laydown'],
            displayNames: const {
              'vertical': 'Vertical Tank',
              'laydown': 'Laydown (Horizontal Tank)',
            },
            onChanged: (String? newValue) {
              setState(() => _tankType = newValue!);
            },
          ),
          const SizedBox(height: 10),

          // --- Full Inches ---
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Full Inches (Full Trycock at “full”):'),
              Row(
                children: [
                  Expanded(child: _buildTextField(_fullInchesController, '0')),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Horizontal Measure Tool is not included in this code.',
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A73E8),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    child: const Text('Horizontal Measure'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Use Horizontal Measure to capture cylinder size from a photo/live view. This will not overwrite Full Trycock inches.',
                style: TextStyle(color: Color(0xFF667085), fontSize: 12),
              ),
            ],
          ),

          // --- Laydown Geometry Fields ---
          if (isLaydown)
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Tank Diameter (in)'),
                        _buildTextField(
                          _geoDiameterController,
                          'e.g., 72',
                          enabled: isLaydown,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Enter manually or auto-filled from Horizontal Measure. Used for laydown geometry.',
                          style: TextStyle(
                            color: Color(0xFF667085),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Tank Length (in)'),
                        _buildTextField(
                          _geoLengthController,
                          'e.g., 300',
                          enabled: isLaydown,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Enter manually or auto-filled from Horizontal Measure. Informational; SCF uses Full Capacity.',
                          style: TextStyle(
                            color: Color(0xFF667085),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),

          // --- Full Capacity ---
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Full Capacity:'),
              Row(
                children: [
                  Expanded(child: _buildTextField(_fullCapController, '0')),
                  const SizedBox(width: 6),
                  DropdownButton<String>(
                    value: _capUnit,
                    items: const [
                      DropdownMenuItem(value: 'scf', child: Text('SCF')),
                      DropdownMenuItem(value: 'gal', child: Text('Gallons')),
                    ],
                    onChanged: (String? newValue) {
                      setState(() => _capUnit = newValue!);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Enter the tank’s rated capacity at “full.”',
                style: TextStyle(color: Color(0xFF667085), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // --- Select Gas ---
          _buildDropdown(
            label: 'Select Gas:',
            value: _gasKey,
            items: GasConstants.gases.keys.toList(),
            displayNames: const {
              'LIN': 'LIN (Nitrogen)',
              'LOX': 'LOX (Oxygen)',
              'LAR': 'LAR (Argon)',
            },
            onChanged: (val) {
              setState(() => _gasKey = val!);
            },
          ),
          const SizedBox(height: 10),

          // --- Start/End Inches ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Start Inches:'),
                    _buildTextField(_startInchesController, '0'),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('End Inches:'),
                    _buildTextField(_endInchesController, '0'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Enter the change in Full Trycock inches (End − Start). Laydown inches are mapped via geometry using the cylinder diameter.',
            style: TextStyle(color: Color(0xFF667085), fontSize: 12),
          ),
          const SizedBox(height: 20),

          // --- Timer / Flow Section (Box) ---
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Timer (optional)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Use the timer and average flow to estimate transfer. You can also estimate the tank diameter from timer data.',
                  style: TextStyle(color: Color(0xFF667085), fontSize: 12),
                ),
                const SizedBox(height: 12),

                // Timer Controls
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: widget.t0 == null || widget.t1 != null
                          ? widget.startTimer
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A73E8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        minimumSize: Size.zero,
                      ),
                      child: const Text(
                        'Start Timer',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: widget.t0 != null && widget.t1 == null
                          ? widget.stopTimer
                          : null,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFEEEEEE),
                        foregroundColor: const Color(0xFF111111),
                        side: const BorderSide(color: Color(0xFFCCCCCC)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        minimumSize: Size.zero,
                      ),
                      child: const Text(
                        'Stop Timer',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    Text(
                      'Elapsed: ${_formatDuration(widget.elapsed)}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Flow Input & Toggle
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Avg Flow'),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  _flowValueController,
                                  'enter value',
                                  padding: 8,
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () =>
                                    setState(() => _isLbMode = !_isLbMode),
                                child: Container(
                                  width: 68,
                                  height: 32,
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: _isLbMode
                                        ? const Color(0xFFCFE1FF)
                                        : const Color(0xFFE6E6E6),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: _isLbMode
                                          ? const Color(0xFF9EC2FF)
                                          : const Color(0xFFCCCCCC),
                                      width: 1,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      const Align(
                                        alignment: Alignment.center,
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8.0,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'gal',
                                                style: TextStyle(fontSize: 11),
                                              ),
                                              Text(
                                                'lb',
                                                style: TextStyle(fontSize: 11),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      AnimatedAlign(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        curve: Curves.easeOut,
                                        alignment: _isLbMode
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft,
                                        child: Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              50,
                                            ),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Colors.black12,
                                                offset: Offset(0, 1),
                                                blurRadius: 2,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Toggle left = Gallons/min (default), right = Pounds/min.',
                            style: TextStyle(
                              color: Color(0xFF667085),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Checkboxes
                Column(
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _chkEstimateD,
                          onChanged: (bool? value) =>
                              setState(() => _chkEstimateD = value!),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        const Text(
                          'Estimate diameter from timer',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),

                    Row(
                      children: [
                        Checkbox(
                          value: _useTimerPrimary,
                          onChanged: (bool? value) =>
                              setState(() => _useTimerPrimary = value!),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        Text(
                          'Use timer as primary (ignore inches for total)',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  'Use timer as primary (ignore inches for total)When "Use timer as primary" is on, total moved = (elapsed minutes × Flow) → converted to SCF by gas. Inches still show as a cross-check.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- Actions ---
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _calculate,
                  child: const Text('Calculate'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearForm,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFEEEEEE),
                    foregroundColor: const Color(0xFF111111),
                    side: const BorderSide(color: Color(0xFFCCCCCC)),
                  ),
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: widget.goToSplit,
                child: const Text('→ Split'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // --- Results Output ---
          _buildResultWidget(context),
        ],
      ),
    );
  }

  // --- Widget Helpers ---

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(text, style: const TextStyle(fontSize: 16)),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    bool enabled = true,
    double padding = 10,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      enabled: enabled,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade200,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: padding),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Map<String, String> displayNames,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                displayNames[item] ?? item,
                style: const TextStyle(fontSize: 16),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildResultWidget(BuildContext context) {
    if (_result == null) {
      return const Text('Enter values and tap Calculate.');
    }

    final result = _result!;
    final gas = result.gas;

    // Number formatting helper
    String fmt(double? n, {int dp = 2}) {
      if (n == null || !n.isFinite) return '—';
      final pattern = '#,##0.${"0" * dp}'; // e.g. 2dp -> "#,##0.00"
      return NumberFormat(pattern).format(n);
    }

    String fmtTime(Duration d) => _formatDuration(d);

    String compLine = '';
    if (result.scfTimer != null && result.scfInches != null) {
      final pct = result.scfInches! == 0
          ? 0.0
          : ((result.scfTimer! - result.scfInches!) / result.scfInches!) * 100;
      compLine = 'Timer vs Inches Δ: ${fmt(pct)}%';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Results — ${result.source}${result.modeLabel.isNotEmpty ? " • ${result.modeLabel}" : ""}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const Divider(),
          if (result.scfInches != null)
            _buildResultRow('SCF from inches', fmt(result.scfInches)),
          if (result.diameterUsed != null)
            _buildResultRow(
              'Diameter used (in)',
              '${fmt(result.diameterUsed!)}${result.estNote ?? ''}',
            ),
          if (result.scfPerInch != null)
            _buildResultRow(
              'Approx. SCF per inch (local)',
              fmt(result.scfPerInch!),
            ),
          if (compLine.isNotEmpty)
            Text(compLine, style: const TextStyle(fontWeight: FontWeight.w500)),

          const Divider(),
          const SizedBox(height: 4),

          _buildResultRow('Total SCF (official)', fmt(result.totalScf)),
          _buildResultRow(
            'Gallons (~SCF ÷ ${fmt(gas.scfPerGal, dp: 2)})',
            fmt(result.totalGallons),
          ),
          _buildResultRow(
            'Pounds (Gallons × ${fmt(gas.lbPerGal, dp: 2)})',
            fmt(result.poundsFromGallons),
          ),
          _buildResultRow(
            'Pounds (SCF ÷ ${fmt(gas.scfPerLb, dp: 2)})',
            fmt(result.poundsFromScf),
          ),

          const SizedBox(height: 8),

          _buildResultRow('Timer', fmtTime(widget.elapsed)),

          if (result.flowGpm != null)
            _buildResultRow(
              'Entered Flow',
              '${fmt(result.flowGpm, dp: 1)} gal/min (${fmt(result.flowLbpm, dp: 1)} lb/min)',
            ),

          if (result.flowGpm == null &&
              result.elapsedMinutes != null &&
              result.elapsedMinutes! > 0)
            _buildResultRow(
              'Flow from timer + result',
              '${fmt(result.totalScf / result.elapsedMinutes! / gas.scfPerGal, dp: 1)} gal/min'
                  ' (${fmt(result.totalScf / result.elapsedMinutes! / gas.scfPerLb, dp: 1)} lb/min)',
            ),
        ],
      ),
    );
  }
}

// --- 5. SPLIT PANE IMPLEMENTATION ---

class _SplitPane extends StatefulWidget {
  final double lastCalculatedSCF;
  final VoidCallback goToCalc;
  final VoidCallback goToReserve;

  const _SplitPane({
    required this.lastCalculatedSCF,
    required this.goToCalc,
    required this.goToReserve,
  });

  @override
  State<_SplitPane> createState() => _SplitPaneState();
}

class _SplitPaneState extends State<_SplitPane> {
  final TextEditingController _totalScfController = TextEditingController();
  final TextEditingController _t1sController = TextEditingController();
  final TextEditingController _t1eController = TextEditingController();
  final TextEditingController _t2sController = TextEditingController();
  final TextEditingController _t2eController = TextEditingController();
  final TextEditingController _t1CapController = TextEditingController();
  final TextEditingController _t2CapController = TextEditingController();

  String _gasKey = 'LIN';
  String _t1Allocated = '0';
  String _t2Allocated = '0';
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.lastCalculatedSCF > 0) {
      _totalScfController.text = widget.lastCalculatedSCF.round().toString();
    }
  }

  @override
  void didUpdateWidget(covariant _SplitPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lastCalculatedSCF != oldWidget.lastCalculatedSCF &&
        (_totalScfController.text.isEmpty || _totalScfController.text == '0')) {
      _totalScfController.text = widget.lastCalculatedSCF.round().toString();
    }
  }

  void _calculateSplit() {
    final scfTotal = double.tryParse(_totalScfController.text) ?? 0;
    final d1 =
        (double.tryParse(_t1eController.text) ?? 0) -
        (double.tryParse(_t1sController.text) ?? 0);
    final d2 =
        (double.tryParse(_t2eController.text) ?? 0) -
        (double.tryParse(_t2sController.text) ?? 0);

    if (scfTotal <= 0 || d1 <= 0 || d2 <= 0) {
      setState(() {
        _error =
            "Enter Total SCF and valid Start/End for both tanks. End must be greater than Start.";
        _t1Allocated = '0';
        _t2Allocated = '0';
      });
      return;
    }

    final sum = d1 + d2;
    int a1 = ((d1 / sum) * scfTotal).round();
    int a2 = ((d2 / sum) * scfTotal).round();

    // Nudge to exact total
    a2 += scfTotal.round() - (a1 + a2);

    setState(() {
      _error = null;
      _t1Allocated = NumberFormat('#,##0').format(a1);
      _t2Allocated = NumberFormat('#,##0').format(a2);
    });
  }

  void _clearSplit() {
    setState(() {
      _totalScfController.clear();
      _t1sController.clear();
      _t1eController.clear();
      _t2sController.clear();
      _t2eController.clear();
      _t1CapController.clear();
      _t2CapController.clear();
      _t1Allocated = '0';
      _t2Allocated = '0';
      _error = null;
    });
  }

  String _formatScf(String scfStr) {
    final scf = double.tryParse(scfStr.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
    if (scf == 0) return '';
    final gas = GasConstants.gases[_gasKey]!;
    final gal = scf / gas.scfPerGal;
    return '≈ ${gal.toStringAsFixed(1)} gal ($_gasKey)';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cryo Split Calculator',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // --- Total SCF and Gas ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total SCF',
                      style: TextStyle(color: Color(0xFF667085), fontSize: 12),
                    ),
                    _buildSplitTextField(_totalScfController, '0'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(fontSize: 14),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('Update'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gas (for SCF ⇄ gallons)',
                      style: TextStyle(color: Color(0xFF667085), fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    DropdownButtonFormField<String>(
                      value: _gasKey,
                      items: GasConstants.gases.keys
                          .map(
                            (key) => DropdownMenuItem(
                              value: key,
                              child: Text('$key'),
                            ),
                          )
                          .toList(),
                      onChanged: (String? newValue) =>
                          setState(() => _gasKey = newValue!),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // SCF to Gallons Hint
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
            child: Text(
              _formatScf(_totalScfController.text).isNotEmpty
                  ? _formatScf(_totalScfController.text)
                  : 'Gas (for SCF ⇄ Gallons)',
              style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
            ),
          ),

          // --- Tank 1 ---
          _buildTankSection(
            header: 'Tank 1',
            capController: _t1CapController,
            sController: _t1sController,
            eController: _t1eController,
            allocatedScf: _t1Allocated,
            allocatedHint: _formatScf(_t1Allocated),
          ),

          // --- Tank 2 ---
          _buildTankSection(
            header: 'Tank 2',
            capController: _t2CapController,
            sController: _t2sController,
            eController: _t2eController,
            allocatedScf: _t2Allocated,
            allocatedHint: _formatScf(_t2Allocated),
          ),

          // --- Error Display ---
          if (_error != null)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEFEF),
                border: Border.all(color: const Color(0xFFF3B3B0)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: Color(0xFFB42318)),
              ),
            ),

          const SizedBox(height: 20),

          // --- Sticky Actions (Footer) ---
          Container(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _calculateSplit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text(
                      'Calculate',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearSplit,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFEEEEEE),
                      foregroundColor: const Color(0xFF111111),
                      side: const BorderSide(color: Color(0xFFCCCCCC)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Clear', style: TextStyle(fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: widget.goToReserve,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text(
                    '> Reserve',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildSplitTextField(
    TextEditingController controller,
    String hint, {
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: readOnly ? BorderSide.none : const BorderSide(),
        ),
      ),
    );
  }

  Widget _buildTankSection({
    required String header,
    required TextEditingController capController,
    required TextEditingController sController,
    required TextEditingController eController,
    required String allocatedScf,
    required String allocatedHint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            header,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Full Trycock (in) & Tank Capacity (gal)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Full Trycock (in)',
                      style: TextStyle(color: Color(0xFF667085), fontSize: 12),
                    ),
                    _buildSplitTextField(capController, '0'),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tank Capacity (gal)',
                      style: TextStyle(color: Color(0xFF667085), fontSize: 12),
                    ),
                    _buildSplitTextField(capController, '0'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Start & End
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Start (in)',
                      style: TextStyle(color: Color(0xFF667085), fontSize: 12),
                    ),
                    _buildSplitTextField(sController, '0'),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'End (in)',
                      style: TextStyle(color: Color(0xFF667085), fontSize: 12),
                    ),
                    _buildSplitTextField(eController, '0'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Allocated SCF
          const Text(
            'Total Allocated SCF',
            style: TextStyle(color: Color(0xFF667085), fontSize: 12),
          ),
          _buildSplitTextField(
            TextEditingController(text: allocatedScf),
            '0',
            readOnly: true,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              allocatedHint.isNotEmpty ? allocatedHint : '',
              style: const TextStyle(color: Color(0xFF667085), fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

// --- 6. RESERVE PANE IMPLEMENTATION ---

class _ReservePane extends StatefulWidget {
  final VoidCallback goToCalc;

  const _ReservePane({required this.goToCalc});

  @override
  State<_ReservePane> createState() => _ReservePaneState();
}

class _ReservePaneState extends State<_ReservePane> {
  final TextEditingController _resGallonsController = TextEditingController();
  final TextEditingController _resTruckFullInController =
      TextEditingController();
  final TextEditingController _resT1Controller = TextEditingController();
  final TextEditingController _resT2Controller = TextEditingController();
  final TextEditingController _resT3Controller = TextEditingController();
  final TextEditingController _resT4Controller = TextEditingController();

  String _resGasKey = 'LIN';
  double _maxSCF = 0;
  String _resRemaining = '0';
  String _resTruckRemainIn = '0';
  String _resHint = '';

  @override
  void initState() {
    super.initState();
    _resT1Controller.addListener(_recomputeRemaining);
    _resT2Controller.addListener(_recomputeRemaining);
    _resT3Controller.addListener(_recomputeRemaining);
    _resT4Controller.addListener(_recomputeRemaining);
    _resTruckFullInController.addListener(_recomputeRemaining);
  }

  @override
  void dispose() {
    _resT1Controller.removeListener(_recomputeRemaining);
    _resT2Controller.removeListener(_recomputeRemaining);
    _resT3Controller.removeListener(_recomputeRemaining);
    _resT4Controller.removeListener(_recomputeRemaining);
    _resTruckFullInController.removeListener(_recomputeRemaining);
    super.dispose();
  }

  void _convertPoundsToSCF() {
    final lbs = double.tryParse(_resGallonsController.text) ?? 0;
    final gas = GasConstants.gases[_resGasKey];

    if (lbs <= 0 || gas == null) {
      setState(() {
        _maxSCF = 0;
        _resHint = '';
        _resRemaining = '0';
        _resTruckRemainIn = '0';
      });
      return;
    }

    final calcSCF = (lbs * gas.scfPerLb).roundToDouble();
    final newMaxSCF = min(999999.0, calcSCF);

    setState(() {
      _maxSCF = newMaxSCF;
      _resHint = calcSCF > 999999
          ? '≈ ${NumberFormat('#,##0').format(calcSCF)} SCF (capped to 999,999 for counter)'
          : '≈ ${NumberFormat('#,##0').format(calcSCF)} SCF';

      _clampTankValue(_resT1Controller);
      _clampTankValue(_resT2Controller);
      _clampTankValue(_resT3Controller);
      _clampTankValue(_resT4Controller);

      _recomputeRemaining();
    });
  }

  void _clampTankValue(TextEditingController controller) {
    final val = double.tryParse(controller.text) ?? 0;
    if (val > _maxSCF) {
      controller.text = _maxSCF.round().toString();
    }
  }

  void _recomputeRemaining() {
    final t1 = double.tryParse(_resT1Controller.text) ?? 0;
    final t2 = double.tryParse(_resT2Controller.text) ?? 0;
    final t3 = double.tryParse(_resT3Controller.text) ?? 0;
    final t4 = double.tryParse(_resT4Controller.text) ?? 0;

    final sum = t1 + t2 + t3 + t4;
    double remaining = _maxSCF - sum;

    setState(() {
      if (remaining < 0 && _maxSCF > 0) {
        _resRemaining = 'Exceeded!';
      } else {
        _resRemaining = NumberFormat('#,##0').format(max(0, remaining));
      }

      _updateTruckInches(max(0, remaining));
    });
  }

  void _updateTruckInches(double remaining) {
    final fullIn = double.tryParse(_resTruckFullInController.text) ?? 0;
    if (_maxSCF <= 0 || fullIn <= 0) {
      _resTruckRemainIn = fullIn > 0 ? fullIn.round().toString() : '0';
      return;
    }
    final ratio = remaining / _maxSCF;
    _resTruckRemainIn = (fullIn * ratio).round().toString();
  }

  void _clearReserve() {
    setState(() {
      _resGallonsController.clear();
      _resTruckFullInController.clear();
      _resT1Controller.clear();
      _resT2Controller.clear();
      _resT3Controller.clear();
      _resT4Controller.clear();
      _resGasKey = 'LIN';
      _maxSCF = 0;
      _resRemaining = '0';
      _resTruckRemainIn = '0';
      _resHint = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cryo Reserve Calculator',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // --- Total Pounds / Gallons to SCF ---
          const Text(
            'Total Pounds /Gallons to SCF',
            style: TextStyle(color: Color(0xFF667085), fontSize: 12),
          ),
          Row(
            children: [
              Expanded(
                child: _buildReserveTextField(_resGallonsController, '0'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _convertPoundsToSCF,
                child: const Text('Update'),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.only(top: 4.0),
            child: Text(
              'Pounds on COA translated to SCF (uses gas below, max 6 digits). SCF is capped at 999,999',
              style: TextStyle(color: Color(0xFF667085), fontSize: 12),
            ),
          ),
          if (_resHint.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                _resHint,
                style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),

          // --- Gas Selection ---
          _buildReserveDropdown(
            label: 'Gas:',
            value: _resGasKey,
            items: GasConstants.gases.keys.toList(),
            onChanged: (String? newValue) {
              setState(() => _resGasKey = newValue!);
            },
          ),
          const SizedBox(height: 12),

          // --- Truck Inches ---
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Truck Full Inches (fallback)',
                      style: TextStyle(color: Color(0xFF667085), fontSize: 12),
                    ),
                    _buildReserveTextField(
                      _resTruckFullInController,
                      'e.g. 120',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Truck Remaining Inches',
                      style: TextStyle(color: Color(0xFF667085), fontSize: 12),
                    ),
                    _buildReserveTextField(
                      TextEditingController(text: _resTruckRemainIn),
                      '0',
                      readOnly: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // --- Tank SCF Inputs ---
          _buildScfInput('Tank 1 SCF', _resT1Controller),
          _buildScfInput('Tank 2 SCF', _resT2Controller),
          _buildScfInput('Tank 3 SCF', _resT3Controller),
          _buildScfInput('Tank 4 SCF', _resT4Controller),

          const SizedBox(height: 16),

          // --- Remaining SCF ---
          const Text(
            'Remaining SCF',
            style: TextStyle(color: Color(0xFF667085), fontSize: 12),
          ),
          _buildReserveTextField(
            TextEditingController(text: _resRemaining),
            '0',
            readOnly: true,
            isError: _resRemaining == 'Exceeded!',
          ),

          const SizedBox(height: 20),

          // --- Sticky Actions (Footer) ---
          Container(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _clearReserve,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Clear', style: TextStyle(fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    onPressed: widget.goToCalc,
                    child: const Text('← Home', style: TextStyle(fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildReserveTextField(
    TextEditingController controller,
    String hint, {
    bool readOnly = false,
    bool isError = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(
        fontSize: 16,
        color: isError ? const Color(0xFFB42318) : Colors.black,
        fontWeight: isError ? FontWeight.bold : FontWeight.normal,
      ),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: readOnly ? BorderSide.none : const BorderSide(),
        ),
      ),
    );
  }

  Widget _buildReserveDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6.0),
          child: Text(label, style: const TextStyle(fontSize: 16)),
        ),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                '$item (${item == "LIN"
                    ? "Nitrogen"
                    : item == "LOX"
                    ? "Oxygen"
                    : "Argon"})',
                style: const TextStyle(fontSize: 16),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildScfInput(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          _buildReserveTextField(controller, '0'),
        ],
      ),
    );
  }
}
