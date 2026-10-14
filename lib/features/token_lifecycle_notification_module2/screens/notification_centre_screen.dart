import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_accessibility.dart';

import '../../auth_live_queue_module3/services/auth_service.dart';
import '../../patient_appointment_scheduling_module1/backend/services/profile_service.dart';

import '../models/notification_model.dart';

import 'notification_detail_screen.dart';
import 'notification_settings_screen.dart';

class NotificationCentreScreen extends StatelessWidget {
  const NotificationCentreScreen({
    super.key,
  });

  String get _currentUserId {
    try {
      final profile =
          ProfileService.activeProfileNotifier.value;

      if (profile.nic.trim().isNotEmpty &&
          profile.nic.trim() != 'N/A') {
        return profile.nic.trim();
      }

      if (profile.patientId.trim().isNotEmpty) {
        return profile.patientId.trim();
      }
    } catch (_) {}

    try {
      final user = AuthService().currentUser;

      if (user != null) {
        if (user.userId.trim().isNotEmpty) {
          return user.userId.trim();
        }

        if (user.nic != null &&
            user.nic!.trim().isNotEmpty) {
          return user.nic!.trim();
        }

        if (user.phoneNumber.trim().isNotEmpty) {
          return user.phoneNumber.trim();
        }
      }
    } catch (_) {}

    return '';
  }

  Set<String> get _validUserIds {
    final ids = <String>{
      'all',
      'broadcast',
    };

    try {
      final profile =
          ProfileService.activeProfileNotifier.value;

      if (profile.nic.trim().isNotEmpty &&
          profile.nic.trim() != 'N/A') {
        ids.add(profile.nic.trim());
      }

      if (profile.patientId.trim().isNotEmpty) {
        ids.add(profile.patientId.trim());
      }
    } catch (_) {}

    try {
      final user = AuthService().currentUser;

      if (user != null) {
        if (user.userId.trim().isNotEmpty) {
          ids.add(user.userId.trim());
        }

        if (user.nic != null &&
            user.nic!.trim().isNotEmpty) {
          ids.add(user.nic!.trim());
        }

        if (user.phoneNumber.trim().isNotEmpty) {
          ids.add(user.phoneNumber.trim());
        }
      }
    } catch (_) {}

    final currentId = _currentUserId;

    if (currentId.isNotEmpty) {
      ids.add(currentId);
    }

    return ids;
  }

  Future<void> _markAsRead(
    NotificationModel notification,
  ) async {
    if (notification.isRead) return;

    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notification.id)
          .update({
        'isRead': true,
        'status': 'READ',
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint(
        'Failed to mark notification as read: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        AppAccessibility.isHighContrastMode,
        ProfileService.activeProfileNotifier,
      ]),
      builder: (context, _) {
        final isDark =
            AppAccessibility.isHighContrastMode.value;

        return Scaffold(
          backgroundColor: isDark
              ? AppColors.seniorHighContrastBg
              : AppColors.background,
          appBar: AppBar(
            backgroundColor: isDark
                ? AppColors.seniorHighContrastSurface
                : Colors.white,
            elevation: 0,
            leading: Navigator.canPop(context)
                ? IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: isDark
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  )
                : null,
            title: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Sri Lanka National Health Alerts',
                  style: TextStyle(
                    color: isDark
                        ? AppColors
                            .seniorHighContrastAccent
                        : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.settings_outlined,
                  color: isDark
                      ? Colors.white
                      : Colors.black87,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const NotificationSettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                      ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return _emptyState(
                  isDark: isDark,
                  icon: Icons.error_outline,
                  title:
                      'Unable to load notifications',
                  message:
                      'Please check your connection and try again.',
                );
              }

              final List<NotificationModel>
                  displayList = [];

              if (snapshot.hasData &&
                  snapshot.data!.docs.isNotEmpty) {
                final validIds = _validUserIds;

                debugPrint(
                  'NotificationCentre valid user IDs: $validIds',
                );

                final matchedDocs =
                    snapshot.data!.docs.where((doc) {
                  final data = doc.data();

                  final uId =
                      (data['userId'] ?? '')
                          .toString()
                          .trim();

                  final pId =
                      (data['patientId'] ?? '')
                          .toString()
                          .trim();

                  final pNic =
                      (data['patientNic'] ?? '')
                          .toString()
                          .trim();

                  final pPhone =
                      (data['phone'] ??
                              data['phoneNumber'] ??
                              '')
                          .toString()
                          .trim();

                  final caregiverId =
                      (data['caregiverId'] ?? '')
                          .toString()
                          .trim();

                  final isBroadcast =
                      data['isBroadcast'] == true ||
                          data['broadcast'] == true ||
                          uId == 'all' ||
                          uId == 'broadcast';

                  final isMatch =
                      isBroadcast ||
                          validIds.contains(uId) ||
                          validIds.contains(pId) ||
                          validIds.contains(pNic) ||
                          validIds.contains(pPhone) ||
                          validIds
                              .contains(caregiverId);

                  return isMatch;
                }).toList();

                matchedDocs.sort((a, b) {
                  final aCreated =
                      a.data()['createdAt'];

                  final bCreated =
                      b.data()['createdAt'];

                  if (aCreated is Timestamp &&
                      bCreated is Timestamp) {
                    return bCreated
                        .compareTo(aCreated);
                  }

                  if (aCreated is Timestamp &&
                      bCreated is! Timestamp) {
                    return -1;
                  }

                  if (aCreated is! Timestamp &&
                      bCreated is Timestamp) {
                    return 1;
                  }

                  return 0;
                });

                for (final doc in matchedDocs) {
                  try {
                    displayList.add(
                      NotificationModel
                          .fromFirestore(
                        doc.id,
                        doc.data(),
                      ),
                    );
                  } catch (e) {
                    debugPrint(
                      'Notification parse error for ${doc.id}: $e',
                    );
                  }
                }
              }

              if (displayList.isEmpty) {
                return _emptyState(
                  isDark: isDark,
                  icon: Icons
                      .notifications_none_rounded,
                  title: 'No notifications yet',
                  message:
                      'Your appointment and queue alerts will appear here.',
                );
              }

              return ListView.builder(
                padding:
                    const EdgeInsets.all(16),
                itemCount: displayList.length,
                itemBuilder: (context, index) {
                  final notification =
                      displayList[index];

                  return GestureDetector(
                    onTap: () async {
                      await _markAsRead(
                        notification,
                      );

                      if (!context.mounted) {
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              NotificationDetailScreen(
                            notification:
                                notification,
                          ),
                        ),
                      );
                    },
                    child: notificationCard(
                      notification,
                      isDark: isDark,
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _emptyState({
    required bool isDark,
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 58,
              color: isDark
                  ? Colors.white70
                  : AppColors.textSecondary,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? Colors.white
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? Colors.white70
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget notificationCard(
    NotificationModel notification, {
    bool isDark = false,
  }) {
    Color color;
    IconData icon;

    switch (notification.type) {
      case 'near_turn':
      case 'queue_approaching':
      case 'caregiver_queue_approaching':
        color = Colors.orange;
        icon =
            Icons.notifications_active_outlined;
        break;

      case 'delay':
      case 'delay_broadcast':
      case 'queue_delayed':
        color = Colors.orange;
        icon = Icons.warning_amber_rounded;
        break;

      case 'missed_token':
      case 'missed_turn':
      case 'missed':
        color = Colors.red;
        icon = Icons.error_outline;
        break;

      case 'your_turn':
      case 'caregiver_your_turn':
        color = Colors.red;
        icon = Icons.priority_high_rounded;
        break;

      case 'appointment_confirmed':
        color = Colors.green;
        icon =
            Icons.check_circle_outline;
        break;

      case 'reminder':
        color = Colors.blue;
        icon =
            Icons.calendar_month_outlined;
        break;

      default:
        color = Colors.blue;
        icon =
            Icons.notifications_none_outlined;
    }

    final bool isUnread =
        !notification.isRead;

    return Container(
      margin:
          const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors
                .seniorHighContrastSurface
            : Colors.white,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? AppColors
                  .seniorHighContrastBorder
              : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title.isEmpty
                            ? 'Notification'
                            : notification.title,
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : AppColors
                                  .textDark,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      margin:
                          const EdgeInsets.only(
                        left: 8,
                      ),
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isUnread
                            ? (isDark
                                ? Colors.red
                                    .withValues(
                                    alpha: 0.25,
                                  )
                                : Colors
                                    .red.shade50)
                            : (isDark
                                ? Colors.grey
                                    .withValues(
                                    alpha: 0.25,
                                  )
                                : Colors.grey
                                    .shade100),
                        borderRadius:
                            BorderRadius.circular(
                          4,
                        ),
                        border: isDark
                            ? Border.all(
                                color: isUnread
                                    ? Colors
                                        .redAccent
                                    : Colors
                                        .grey,
                              )
                            : null,
                      ),
                      child: Text(
                        isUnread
                            ? 'UNREAD'
                            : 'READ',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              FontWeight.bold,
                          color: isUnread
                              ? (isDark
                                  ? Colors
                                      .redAccent
                                  : Colors.red)
                              : (isDark
                                  ? Colors.grey
                                      .shade300
                                  : Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  notification.message.isEmpty
                      ? 'No details available.'
                      : notification.message,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(
                            0xFFCBD5E1,
                          )
                        : AppColors
                            .textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}