import 'package:flutter/material.dart';
import 'journey_planner.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String? selectedCarModel;
  double batteryPercent = 50;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;

  final List<Map<String, dynamic>> carModels = [
    {
      'name': 'Tesla Model 3',
      'range': '358 mi',
      'icon': '🚗',
      'color': Color(0xFFE31E24)
    },
    {
      'name': 'Nissan Leaf',
      'range': '226 mi',
      'icon': '🍃',
      'color': Color(0xFF1B73E8)
    },
    {
      'name': 'Chevy Bolt',
      'range': '259 mi',
      'icon': '⚡',
      'color': Color(0xFFFFA000)
    },
    {
      'name': 'BMW i3',
      'range': '153 mi',
      'icon': '🔋',
      'color': Color(0xFF00D4AA)
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Color _getBatteryColor() {
    if (batteryPercent > 60) return Color(0xFF00E676);
    if (batteryPercent > 30) return Color(0xFFFFD54F);
    return Color(0xFFFF5252);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0E27),
              Color(0xFF1A1F3A),
              Color(0xFF2D3561),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _slideAnimation.value),
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF64B5F6), Color(0xFF42A5F5)],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF42A5F5).withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.electric_car_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'EV Journey Planner',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Text(
                                      'Plan your electric adventure',
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 40),

                          // Car Selection Card
                          Container(
                            padding: EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.directions_car_rounded,
                                      color: Color(0xFF64B5F6),
                                      size: 24,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Select Vehicle',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 20),

                                // Car Models Grid
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 1.2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  itemCount: carModels.length,
                                  itemBuilder: (context, index) {
                                    final car = carModels[index];
                                    final isSelected = selectedCarModel == car['name'];

                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedCarModel = car['name'];
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration: Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                        padding: EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          gradient: isSelected
                                              ? LinearGradient(
                                            colors: [
                                              car['color'].withOpacity(0.3),
                                              car['color'].withOpacity(0.1),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                              : null,
                                          color: isSelected ? null : Colors.white.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isSelected
                                                ? car['color']
                                                : Colors.white.withOpacity(0.1),
                                            width: isSelected ? 2 : 1,
                                          ),
                                          boxShadow: isSelected ? [
                                            BoxShadow(
                                              color: car['color'].withOpacity(0.3),
                                              blurRadius: 12,
                                              offset: Offset(0, 4),
                                            ),
                                          ] : null,
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              car['icon'],
                                              style: TextStyle(fontSize: 24),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              car['name'],
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              car['range'],
                                              style: TextStyle(
                                                color: Colors.white60,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 24),

                          // Battery Level Card
                          Container(
                            padding: EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.battery_charging_full_rounded,
                                      color: _getBatteryColor(),
                                      size: 24,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Battery Level',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Spacer(),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getBatteryColor().withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: _getBatteryColor().withOpacity(0.5),
                                        ),
                                      ),
                                      child: Text(
                                        '${batteryPercent.round()}%',
                                        style: TextStyle(
                                          color: _getBatteryColor(),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 20),

                                // Custom Battery Slider
                                Column(
                                  children: [
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        activeTrackColor: _getBatteryColor(),
                                        inactiveTrackColor: Colors.white.withOpacity(0.1),
                                        thumbColor: _getBatteryColor(),
                                        thumbShape: RoundSliderThumbShape(
                                          enabledThumbRadius: 12,
                                        ),
                                        overlayColor: _getBatteryColor().withOpacity(0.2),
                                        trackHeight: 6,
                                      ),
                                      child: Slider(
                                        value: batteryPercent,
                                        min: 0,
                                        max: 100,
                                        divisions: 20,
                                        onChanged: (val) {
                                          setState(() {
                                            batteryPercent = val;
                                          });
                                        },
                                      ),
                                    ),

                                    // Battery indicator
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '0%',
                                          style: TextStyle(
                                            color: Colors.white38,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          'Range: ${(batteryPercent * 3.5).round()} mi',
                                          style: TextStyle(
                                            color: Colors.white60,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          '100%',
                                          style: TextStyle(
                                            color: Colors.white38,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 32),

                          // Plan Route Button
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: selectedCarModel != null ? _pulseAnimation.value : 1.0,
                                child: Container(
                                  width: double.infinity,
                                  height: 60,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (selectedCarModel == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Please select a vehicle first'),
                                            backgroundColor: Color(0xFFFF5252),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (context, animation, secondaryAnimation) =>
                                              JourneyPlannerGoogle(
                                                carModel: selectedCarModel!,
                                                batteryPercent: batteryPercent,
                                              ),
                                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                            return SlideTransition(
                                              position: animation.drive(
                                                Tween(begin: Offset(1.0, 0.0), end: Offset.zero),
                                              ),
                                              child: child,
                                            );
                                          },
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: selectedCarModel != null
                                          ? Color(0xFF00E676)
                                          : Colors.grey.withOpacity(0.3),
                                      foregroundColor: selectedCarModel != null
                                          ? Colors.black
                                          : Colors.white60,
                                      elevation: selectedCarModel != null ? 8 : 0,
                                      shadowColor: selectedCarModel != null
                                          ? Color(0xFF00E676).withOpacity(0.4)
                                          : Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.navigation_rounded,
                                          size: 24,
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Plan Your Journey',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
