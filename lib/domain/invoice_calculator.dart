import '../data/models/invoice_model.dart';

class InvoiceCalculator {
  // Calcule le statut d'une facture selon les montants et la date d'échéance
  static InvoiceStatus computeStatus({
    required double totalAmount,
    required double paidAmount,
    required DateTime dueDate,
  }) {
    if (paidAmount >= totalAmount) return InvoiceStatus.paid;

    final now = DateTime.now();
    final isOverdue = now.isAfter(dueDate);

    if (isOverdue) return InvoiceStatus.late;
    if (paidAmount > 0) return InvoiceStatus.partial;
    return InvoiceStatus.draft;
  }

  // Retourne le solde restant
  static double remainingAmount(double totalAmount, double paidAmount) {
    final remaining = totalAmount - paidAmount;
    return remaining < 0 ? 0 : remaining;
  }

  // Retourne le pourcentage payé (0.0 à 1.0)
  static double paidRatio(double totalAmount, double paidAmount) {
    if (totalAmount <= 0) return 0;
    final ratio = paidAmount / totalAmount;
    return ratio > 1 ? 1 : ratio;
  }
}
