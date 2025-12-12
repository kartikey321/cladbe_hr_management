import 'package:cladbe_hr_management/src/routes/route_config/route_names.dart';
import 'package:cladbe_hr_management/src/ui/tablet_desktop/Holiday/add_holiday.dart';
import 'package:cladbe_hr_management/src/ui/tablet_desktop/Holiday/widgets/holiday_card.dart';
import 'package:cladbe_hr_management/src/ui/tablet_desktop/attendanceDashboard/widgets/stat_card.dart';
import 'package:cladbe_shared/cladbe_shared.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexify/hexify.dart';
import 'package:provider/provider.dart';

class HolidayDashboardScreen extends StatefulWidget {
  const HolidayDashboardScreen({super.key});

  @override
  State<HolidayDashboardScreen> createState() => _HolidayDashboardScreenState();
}

class _HolidayDashboardScreenState extends State<HolidayDashboardScreen> {
  Stream<List<HolidayModel>>? holidayStream;
  String? selectedHolidayId;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  void _initStream() {
    holidayStream = HolidaysHelper.getHolidayDataStream(
      context.getCompanyId(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        /// If anything is selected → unselect
        if (selectedHolidayId != null) {
          setState(() {
            selectedHolidayId = null;
          });
        }
      },
      child: Column(
        spacing: 25,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // _buildStatsGrid([]),

          /// ------------------- ADD HOLIDAY BUTTON -------------------
          Align(
            alignment: Alignment.bottomRight,
            child: InkWell(
              onDoubleTap: () {
                NavigatorHelper.navigateTo(
                  context,
                  Routes.AddHolidayScreen,
                  {},
                );
              },
              child: Container(
                height: 36,
                width: 100,
                margin: const EdgeInsets.only(top: 20),
                decoration: BoxDecoration(
                  color: Hexify(colorCode: "#5A5A5A"),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    "+ Holiday",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),

          /// ------------------- HOLIDAY LIST STREAM -------------------
          CustomStreamBuilder(
            stream: holidayStream,
            builder: (context, snapshot) {
              final holidays = snapshot.data ?? [];

              if (holidays.isEmpty) {
                return Center(
                  child: Text(
                    "No holidays added yet.",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                    ),
                  ),
                );
              }

              return CustomMasnoryGridView(
                children: holidays.map((holiday) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          selectedHolidayId = selectedHolidayId == holiday.id
                              ? null
                              : holiday.id;
                        });
                      },

                      /// DOUBLE TAP — EDIT
                      onDoubleTap: () {
                        NavigatorHelper.navigateTo(
                          context,
                          Routes.AddHolidayScreen,
                          {
                            'holiday': holiday,
                            'holidayId': holiday.id,
                          },
                        );
                        // Provider.of<PopupProvider>(context, listen: false)
                        //     .pushPopupStack = Popup(
                        //   id: "edit-holiday-popup",
                        //   barrierDismissible: true,
                        //   element: Center(
                        //     child: SizedBox(
                        //       height: MediaQuery.of(context).size.height * 0.75,
                        //       width: MediaQuery.of(context).size.width * 0.55,
                        //       child: const AddHoliday(
                        //           // holidayModel: holiday,  <-- if you want edit
                        //           ),
                        //     ),
                        //   ),
                        // );
                      },

                      child: HolidayCard(
                        holiday: holiday,
                        isSelected: selectedHolidayId == holiday.id,
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    List<HolidayModel> data,
  ) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 19,
      children: [
        Expanded(
          flex: 0,
          child: Row(
            spacing: 15,
            children: [
              StatCard(
                title: 'Total Holidays',
                count: "2",
                icon: Icons.people_outline,
              ),
              SizedBox(height: 16),
              StatCard(
                title: 'Total',
                count: "2",
                icon: Icons.people_outline,
              ),
              SizedBox(height: 16),
              StatCard(
                title: 'Total',
                count: "2",
                icon: Icons.people_outline,
              ),
              SizedBox(height: 16),
              StatCard(
                title: 'Total',
                count: "2",
                icon: Icons.people_outline,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
