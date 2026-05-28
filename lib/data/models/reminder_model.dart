enum ReminderType { beforeDue, onDue, afterDue, custom }

enum ReminderChannel { push, whatsapp, sms }

class ReminderModel {
  final String id;
  final String userId;
  final String invoiceId;
  final String clientId;
  final String clientName;
  final String invoiceTitle;
  final double remainingAmount;
  final ReminderType type;
  final ReminderChannel channel;
  final DateTime scheduledAt;
  final DateTime? sentAt;
  final bool isSent;

  const ReminderModel({
    required this.id,
    required this.userId,
    required this.invoiceId,
    required this.clientId,
    required this.clientName,
    required this.invoiceTitle,
    required this.remainingAmount,
    required this.type,
    this.channel = ReminderChannel.push,
    required this.scheduledAt,
    this.sentAt,
    this.isSent = false,
  });

  factory ReminderModel.fromMap(Map<String, dynamic> map, String id) {
    return ReminderModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      invoiceId: map['invoiceId'] as String? ?? '',
      clientId: map['clientId'] as String? ?? '',
      clientName: map['clientName'] as String? ?? '',
      invoiceTitle: map['invoiceTitle'] as String? ?? '',
      remainingAmount: (map['remainingAmount'] as num?)?.toDouble() ?? 0,
      type: ReminderType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => ReminderType.afterDue,
      ),
      channel: ReminderChannel.values.firstWhere(
        (c) => c.name == map['channel'],
        orElse: () => ReminderChannel.push,
      ),
      scheduledAt: DateTime.fromMillisecondsSinceEpoch(
        map['scheduledAt'] as int? ?? 0,
      ),
      sentAt: map['sentAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['sentAt'] as int)
          : null,
      isSent: map['isSent'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'invoiceId': invoiceId,
      'clientId': clientId,
      'clientName': clientName,
      'invoiceTitle': invoiceTitle,
      'remainingAmount': remainingAmount,
      'type': type.name,
      'channel': channel.name,
      'scheduledAt': scheduledAt.millisecondsSinceEpoch,
      'sentAt': sentAt?.millisecondsSinceEpoch,
      'isSent': isSent,
    };
  }

  ReminderModel copyWith({bool? isSent, DateTime? sentAt}) {
    return ReminderModel(
      id: id,
      userId: userId,
      invoiceId: invoiceId,
      clientId: clientId,
      clientName: clientName,
      invoiceTitle: invoiceTitle,
      remainingAmount: remainingAmount,
      type: type,
      channel: channel,
      scheduledAt: scheduledAt,
      sentAt: sentAt ?? this.sentAt,
      isSent: isSent ?? this.isSent,
    );
  }
}
