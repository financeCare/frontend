import 'package:flutter_test/flutter_test.dart';

import 'package:finance_care/features/debt/domain/models/finance_item.dart';
import 'package:finance_care/features/debt/domain/models/debt_dto.dart';
import 'package:finance_care/features/debt/domain/models/debt_request.dart';
import 'package:finance_care/features/debt/domain/models/debt_response.dart';
import 'package:finance_care/features/debt/domain/models/debt_payment_request.dart';
import 'package:finance_care/features/debt/domain/models/debt_transaction_response.dart';
import 'package:finance_care/features/debt/domain/models/monthly_status_response.dart';
import 'package:finance_care/features/debt/domain/models/monthly_debt_status.dart';

import 'package:finance_care/features/debt/data/logic/debt_calculator.dart';
import 'package:finance_care/features/debt/domain/strategies/avalanche_strategy.dart' as domain_avalanche;
import 'package:finance_care/features/debt/domain/strategies/snowball_strategy.dart' as domain_snowball;
import 'package:finance_care/features/debt/data/strategies/avalanche_service.dart' as data_avalanche;
import 'package:finance_care/features/debt/data/strategies/snowball_service.dart' as data_snowball;
import 'package:finance_care/features/debt/data/strategies/fast_track_service.dart' as data_fast_track;
import 'package:finance_care/features/debt/data/strategies/minimum_payment_service.dart' as data_min_pay;

import 'package:finance_care/features/budget/domain/models/budget_dto.dart';

import 'package:finance_care/features/job/data/models/job_model.dart';
import 'package:finance_care/features/job/data/models/occupation_model.dart';

import 'package:finance_care/features/notification/data/models/notification.dart';
import 'package:finance_care/features/notification/data/models/notification_log_item.dart';

import 'package:finance_care/features/settings/data/models/user_setting_response.dart';
import 'package:finance_care/features/simulator/data/models/repayment_strategy_response.dart';

import 'package:finance_care/shared/models/user_device_request.dart';
import 'package:finance_care/shared/models/user_device_response.dart';

import 'package:finance_care/core/config/config.dart' as config;
import 'package:finance_care/core/utils/app_logger.dart';

void main() {
  group('Debt Strategies & Calculator Tests', () {
    test('DebtCalculator with domain AvalancheStrategy', () {
      final strategy = domain_avalanche.AvalancheStrategy();
      final calc = DebtCalculator(strategy);

      final items = [
        FinanceItem(name: 'Debt A', amount: 5000, interest: 5),
        FinanceItem(name: 'Debt B', amount: 10000, interest: 18),
      ];

      final sorted = calc.run(items, 1000);
      expect(sorted.first.name, 'Debt B');
      expect(sorted.first.interest, 18);
    });

    test('DebtCalculator with domain SnowballStrategy', () {
      final strategy = domain_snowball.SnowballStrategy();
      final calc = DebtCalculator(strategy);

      final items = [
        FinanceItem(name: 'Debt A', amount: 5000, interest: 5),
        FinanceItem(name: 'Debt B', amount: 2000, interest: 18),
      ];

      final sorted = calc.run(items, 1000);
      expect(sorted.first.name, 'Debt B');
      expect(sorted.first.amount, 2000);
    });

    test('Data AvalancheStrategy execution', () {
      final strategy = data_avalanche.AvalancheStrategy();
      final items = [
        FinanceItem(name: 'A', amount: 5000, interest: 5),
        FinanceItem(name: 'B', amount: 3000, interest: 15),
      ];

      final res = strategy.calculate(items, 2000);
      expect(res.length, 2);
      expect(res[0].name, 'B');
      expect(res[0].amount, 1000); // 3000 - 2000 = 1000
    });

    test('Data SnowballStrategy execution', () {
      final strategy = data_snowball.SnowballStrategy();
      final items = [
        FinanceItem(name: 'A', amount: 5000, interest: 15),
        FinanceItem(name: 'B', amount: 2000, interest: 5),
      ];

      final res = strategy.calculate(items, 1500);
      expect(res.length, 2);
      expect(res[0].name, 'B');
      expect(res[0].amount, 500); // 2000 - 1500 = 500
    });

    test('Data FastTrackStrategy execution', () {
      final strategy = data_fast_track.FastTrackStrategy();
      final items = [
        FinanceItem(name: 'A', amount: 5000, interest: 10),
      ];

      final res = strategy.calculate(items, 2000);
      expect(res.length, 1);
    });

    test('Data MinimumPaymentStrategy execution', () {
      final strategy = data_min_pay.MinimumPaymentStrategy();
      final items = [
        FinanceItem(name: 'A', amount: 5000, interest: 10),
      ];

      final res = strategy.calculate(items, 500);
      expect(res.length, 1);
    });
  });

  group('Debt Models & DTOs Tests', () {
    test('FinanceItem toJson and fromJson', () {
      final item = FinanceItem(
        name: 'Credit Card',
        amount: 15000.50,
        interest: 16.0,
        type: 'Revolving',
        createdAt: DateTime(2026, 1, 1),
      );

      final json = item.toJson();
      expect(json['name'], 'Credit Card');
      expect(json['amount'], 15000.50);

      final fromJsonItem = FinanceItem.fromJson(json);
      expect(fromJsonItem.name, 'Credit Card');
      expect(fromJsonItem.amount, 15000.50);
      expect(fromJsonItem.interest, 16.0);
    });

    test('DebtDto JSON serialization and totalAmount', () {
      final dto = DebtDto(
        id: '123',
        name: 'Car Loan',
        amount: 200000,
        outstandingAmount: 190000,
        interest: 2.5,
      );

      expect(dto.id, '123');
      expect(dto.name, 'Car Loan');
      expect(dto.amount, 200000);

      final json = dto.toJson();
      expect(json['id'], '123');

      final fromJsonDto = DebtDto.fromJson(json);
      expect(fromJsonDto.name, 'Car Loan');

      final total = DebtDto.totalAmount([dto, dto]);
      expect(total, 400000);
    });

    test('DebtRequest JSON serialization', () {
      final req = DebtRequest(
        principalAmount: 50000,
        interestRate: 12.0,
        repaymentTypeId: 1,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2027, 1, 1),
        isActive: true,
        priority: 1,
        debtTypeId: 2,
        debtName: 'Personal Loan',
        minPayment: 2500,
        dueDay: 5,
        penaltyAnnualRate: 0.05,
        gracePeriodDays: 3,
        penaltyTriggerDays: 7,
      );

      final json = req.toJson();
      expect(json['debtName'], 'Personal Loan');
      expect(json['principalAmount'], 50000);

      final fromJsonReq = DebtRequest.fromJson(json);
      expect(fromJsonReq.debtName, 'Personal Loan');
      expect(fromJsonReq.minPayment, 2500);
    });

    test('DebtResponse JSON deserialization', () {
      final json = {
        'debtId': 'uuid-123',
        'userId': 'user-1',
        'principalAmount': 2000000.0,
        'principalOutstanding': 1950000.0,
        'totalOutstanding': 1960000.0,
        'interestRate': 3.5,
        'interestCalculationType': 'THIRTY_360',
        'interestInterval': 'MONTHLY',
        'paymentInterval': 'MONTHLY',
        'repaymentType': {'repaymentTypeId': 1, 'repaymentTypeName': 'EMI', 'repaymentTypeDescription': 'Equated Monthly'},
        'debtType': {'debtTypeId': 1, 'debtTypeName': 'Mortgage', 'debtTypeDescription': 'Home Mortgage'},
        'startDate': '2026-01-01',
        'endDate': '2056-01-01',
        'priority': 1,
        'debtName': 'Home Loan',
        'isActive': true,
        'minPayment': 15000.0,
        'dueDay': 1,
        'penaltyAnnualRate': 0.05,
        'gracePeriodDays': 5,
        'penaltyTriggerDays': 10,
        'isDefaulted': false,
        'isInformal': false,
      };

      final resp = DebtResponse.fromJson(json);
      expect(resp.debtId, 'uuid-123');
      expect(resp.debtName, 'Home Loan');
      expect(resp.interestRate, 3.5);
      expect(resp.repaymentType.typeName, 'EMI');
      expect(resp.debtType.debtTypeName, 'Mortgage');
    });

    test('MonthlyStatusResponse and MonthlyDebtStatus', () {
      final json = {
        'totalAmount': 500000.0,
        'paidAmount': 20000.0,
        'remainingAmount': 480000.0,
      };

      final status = MonthlyStatusResponse.fromJson(json);
      expect(status.totalAmount, 500000.0);
      expect(status.paidAmount, 20000.0);
      expect(status.remainingAmount, 480000.0);

      final empty = MonthlyStatusResponse.empty();
      expect(empty.totalAmount, 0.0);

      final monthlyDebt = MonthlyDebtStatus(
        totalAmount: 50000,
        paidAmount: 5000,
        remainingAmount: 45000,
        requiredMinPayment: 2500,
        isBudgetInsufficient: false,
      );
      expect(monthlyDebt.totalAmount, 50000);
    });

    test('DebtPaymentRequest and DebtTransactionResponse', () {
      final pReq = DebtPaymentRequest(
        debtId: 'd1',
        amount: 5000.0,
        paidAt: '2026-02-01',
      );
      final json = pReq.toJson();
      expect(json['amount'], 5000.0);

      final txResp = DebtTransactionResponse.fromJson({
        'transactionId': 'tx-1',
        'amount': 5000.0,
        'transactionDate': '2026-02-01T12:00:00',
        'transactionType': 'PAYMENT',
      });
      expect(txResp.transactionId, 'tx-1');
    });
  });

  group('Budget Models Tests', () {
    test('BudgetDto model serialization and totalAmount', () {
      final b = BudgetDto(
        id: 1,
        name: 'Groceries',
        amount: 10000,
      );
      expect(b.id, 1);
      expect(b.amount, 10000);

      final json = b.toJson();
      expect(json['name'], 'Groceries');

      final fromJsonB = BudgetDto.fromJson(json);
      expect(fromJsonB.name, 'Groceries');

      final total = BudgetDto.totalAmount([b, b]);
      expect(total, 20000);
    });
  });

  group('Job & Occupation Models Tests', () {
    test('JobModel and OccupationModel serialization', () {
      final job = JobModel(
        id: 'j1',
        title: 'Flutter Developer',
        type: 'Full-time',
        estimatedIncome: '60,000 THB',
        description: 'Build mobile apps',
        requirement: '2+ years Flutter',
        platformLinks: {'JobsDB': 'https://example.com'},
        isRecommended: true,
      );

      expect(job.title, 'Flutter Developer');
      expect(job.isRecommended, true);

      final occ = OccupationModel(
        title: 'Mobile Developer',
        description: 'Build apps',
        averageIncome: '50000',
        iconType: 'code',
        pros: ['High salary'],
        cons: ['Tight deadlines'],
        potentialKeywords: 'flutter, dart',
        isBestMatch: true,
      );
      expect(occ.title, 'Mobile Developer');
      expect(occ.isBestMatch, true);
    });
  });

  group('Notification & Settings Models Tests', () {
    test('NotificationDTO and Log items', () {
      final notif = NotificationDTO(
        notificationId: 'n1',
        userId: 'u1',
        type: 'PAYMENT',
        message: 'Payment due soon',
        isRead: false,
      );
      expect(notif.notificationId, 'n1');
      expect(notif.isRead, false);

      final logItem = NotificationLogItem.fromJson({
        'logId': '10',
        'ruleId': '1',
        'title': 'Alert',
        'body': 'High spending',
        'status': 'SENT',
        'sentAt': '2026-02-01T10:00:00',
      });
      expect(logItem.logId, '10');
      expect(logItem.title, 'Alert');
    });

    test('UserSetting overview and details', () {
      final json = {
        'userId': 'u1',
        'notificationsEnabled': true,
        'pushEnabled': true,
        'defaultRemindDaysBefore': 3,
        'defaultNotifyTime': '09:00:00',
        'timezone': 'Asia/Bangkok',
        'createdAt': '2026-01-01T00:00:00',
        'updatedAt': '2026-01-01T00:00:00',
      };
      final setting = UserSetting.fromJson(json);
      expect(setting.userId, 'u1');
      expect(setting.notificationsEnabled, true);
      expect(setting.defaultRemindDaysBefore, 3);
    });
  });

  group('Simulator & Device Models Tests', () {
    test('RepaymentStrategyResponse', () {
      final strat = RepaymentStrategyResponse(
        strategyId: 's1',
        strategyName: 'AVALANCHE',
        description: 'Highest interest first',
        isActive: true,
        tags: ['Fast', 'Recommended'],
      );
      expect(strat.strategyName, 'AVALANCHE');
      expect(strat.tags.length, 2);
    });

    test('UserDeviceRequest & Response', () {
      final req = UserDeviceRequest(
        deviceKey: 'key-123',
        fcmToken: 'fcm-token-xyz',
        platform: 'ANDROID',
        deviceName: 'Pixel 8',
      );
      final json = req.toJson();
      expect(json['deviceKey'], 'key-123');
      expect(json['deviceName'], 'Pixel 8');

      final resp = UserDeviceResponse.fromJson({
        'deviceId': 'device-123',
        'isActive': true,
        'lastSeen': '2026-02-01T10:00:00',
      });
      expect(resp.deviceId, 'device-123');
      expect(resp.isActive, true);
    });
  });

  group('Config & Logger Tests', () {
    test('Config URLs exist', () {
      expect(config.baseUrl, isNotEmpty);
    });

    test('AppLogger methods execution without throwing', () {
      AppLog.d('Debug test message');
      AppLog.e('Error test message', 'Sample Error');
      expect(true, isTrue);
    });
  });
}
