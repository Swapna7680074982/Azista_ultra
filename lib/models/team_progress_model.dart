import '../utilities/role_helper.dart';

class TeamMemberSummary {
  final String userId;
  final String employeeId;
  final String fullName;
  final String roleCode;
  final int totalOutlets;
  final int newOutlets;
  final int totalVisits;
  final int totalActivities;
  final int totalPobs;
  final double pobSaleValue;

  TeamMemberSummary({
    required this.userId,
    required this.employeeId,
    required this.fullName,
    required this.roleCode,
    required this.totalOutlets,
    required this.newOutlets,
    required this.totalVisits,
    required this.totalActivities,
    required this.totalPobs,
    required this.pobSaleValue,
  });

  factory TeamMemberSummary.fromJson(Map<String, dynamic> json) {
    return TeamMemberSummary(
      userId: json['user_id']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
      fullName: json['fullname']?.toString() ?? json['employee_name']?.toString() ?? '',
      roleCode: (json['rolecode'] ?? json['role'] ?? '').toString().trim().toUpperCase(),
      totalOutlets: (json['total_outlets'] as num?)?.toInt() ?? 0,
      newOutlets: (json['new_outlets'] as num?)?.toInt() ?? 0,
      totalVisits: (json['total_visits'] as num?)?.toInt() ?? 0,
      totalActivities: (json['total_activities'] as num?)?.toInt() ?? 0,
      totalPobs: (json['total_pobs'] as num?)?.toInt() ?? 0,
      pobSaleValue: (json['pob_sale_value'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Hierarchy sorting priority:
  /// RSM/RM (Regional): 1
  /// ASM/AM (Area): 2
  /// SO/FSE (Field Sales): 3
  /// Others: 4
  int get hierarchyPriority {
    final norm = RoleHelper.normalizeRole(roleCode);
    if (norm == 'RM') return 1;
    if (norm == 'AM') return 2;
    if (norm == 'SO') return 3;
    return 4;
  }
}

class TeamMemberOutlet {
  final int outletId;
  final String outletName;
  final String ownerName;
  final String mobile;
  final String address;
  final int? routeId;
  final String? routeCode;
  final int? assignedUserId;
  final String? assignedUserName;
  final int totalVisits;
  final int totalActivities;
  final int totalPobs;
  final double saleValue;

  TeamMemberOutlet({
    required this.outletId,
    required this.outletName,
    required this.ownerName,
    required this.mobile,
    required this.address,
    this.routeId,
    this.routeCode,
    this.assignedUserId,
    this.assignedUserName,
    required this.totalVisits,
    required this.totalActivities,
    required this.totalPobs,
    required this.saleValue,
  });

  factory TeamMemberOutlet.fromJson(Map<String, dynamic> json) {
    return TeamMemberOutlet(
      outletId: (json['outlet_id'] as num?)?.toInt() ?? int.tryParse(json['outlet_id']?.toString() ?? '0') ?? 0,
      outletName: json['outlet_name']?.toString() ?? '',
      ownerName: json['owner_name']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      routeId: json['route_id'] != null ? (json['route_id'] as num?)?.toInt() : null,
      routeCode: json['route_code']?.toString(),
      assignedUserId: json['assigned_user_id'] != null ? (json['assigned_user_id'] as num?)?.toInt() : null,
      assignedUserName: json['assigned_user_name']?.toString(),
      totalVisits: (json['total_visits'] as num?)?.toInt() ?? 0,
      totalActivities: (json['total_activities'] as num?)?.toInt() ?? 0,
      totalPobs: (json['total_pobs'] as num?)?.toInt() ?? 0,
      saleValue: (json['sale_value'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'outlet_id': outletId,
      'outlet_name': outletName,
      'owner_name': ownerName,
      'mobile': mobile,
      'address': address,
      'route_id': routeId,
      'route_code': routeCode,
      'assigned_user_id': assignedUserId,
      'assigned_user_name': assignedUserName,
      'total_visits': totalVisits,
      'total_activities': totalActivities,
      'total_pobs': totalPobs,
      'sale_value': saleValue,
    };
  }
}

class OutletPobProduct {
  final String id;
  final String pobId;
  final String productId;
  final String skuId;
  final int quantity;
  final double pts;
  final double ptsSubtotal;
  final int suppliedQty;
  final int remainingQty;
  final String productName;
  final String skuDisplayName;

  OutletPobProduct({
    required this.id,
    required this.pobId,
    required this.productId,
    required this.skuId,
    required this.quantity,
    required this.pts,
    required this.ptsSubtotal,
    required this.suppliedQty,
    this.remainingQty = 0,
    required this.productName,
    required this.skuDisplayName,
  });

  factory OutletPobProduct.fromJson(Map<String, dynamic> json) {
    return OutletPobProduct(
      id: json['id']?.toString() ?? '',
      pobId: json['pob_id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      skuId: json['sku_id']?.toString() ?? '',
      quantity: int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      pts: double.tryParse(json['pts']?.toString() ?? json['ptr_price']?.toString() ?? '0') ?? 0.0,
      ptsSubtotal: double.tryParse(json['pts_subtotal']?.toString() ?? json['ptr_subtotal']?.toString() ?? '0') ?? 0.0,
      suppliedQty: int.tryParse(json['supplied_qty']?.toString() ?? '0') ?? 0,
      remainingQty: int.tryParse(json['remaining_qty']?.toString() ?? '0') ?? 0,
      productName: json['product_name']?.toString() ?? '',
      skuDisplayName: json['sku_displayname']?.toString() ?? json['sku_name']?.toString() ?? '',
    );
  }
}

class OutletPobRecord {
  final int id;
  final String pobNumber;
  final String pobType;
  final String status;
  final double ptsTotalAmount;
  final String orderCopy;
  final String? remarks;
  final String createdAt;
  final int createdBy;
  final String createdByName;
  final String createdByEmployeeId;
  final String createdByDesignation;
  final String createdByRole;
  final String createdByMobile;
  final String? suppliedBy;
  final String? suppliedByName;
  final String? suppliedAt;
  final double saleValue;
  final int? outletId;
  final String? outletName;
  final String? ownerName;
  final String? outletMobile;
  final String? outletAddress;
  final List<OutletPobProduct> items;

  OutletPobRecord({
    required this.id,
    required this.pobNumber,
    required this.pobType,
    required this.status,
    required this.ptsTotalAmount,
    required this.orderCopy,
    this.remarks,
    required this.createdAt,
    required this.createdBy,
    required this.createdByName,
    required this.createdByEmployeeId,
    required this.createdByDesignation,
    required this.createdByRole,
    required this.createdByMobile,
    this.suppliedBy,
    this.suppliedByName,
    this.suppliedAt,
    required this.saleValue,
    this.outletId,
    this.outletName,
    this.ownerName,
    this.outletMobile,
    this.outletAddress,
    required this.items,
  });

  factory OutletPobRecord.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] is List ? json['items'] as List : [];
    return OutletPobRecord(
      id: (json['pob_id'] ?? json['id'] as num?)?.toInt() ?? int.tryParse((json['pob_id'] ?? json['id'])?.toString() ?? '0') ?? 0,
      pobNumber: json['pob_number']?.toString() ?? '',
      pobType: json['pob_type']?.toString() ?? 'regular',
      status: json['status']?.toString() ?? 'pending',
      ptsTotalAmount: double.tryParse(json['pts_total_amount']?.toString() ?? json['sale_value']?.toString() ?? '0') ?? 0.0,
      orderCopy: json['order_copy']?.toString() ?? '',
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      createdBy: (json['created_by'] as num?)?.toInt() ?? int.tryParse(json['created_by']?.toString() ?? '0') ?? 0,
      createdByName: json['created_by_name']?.toString() ?? json['employee_name']?.toString() ?? '',
      createdByEmployeeId: json['created_by_employee_id']?.toString() ?? json['employee_id']?.toString() ?? '',
      createdByDesignation: json['created_by_designation']?.toString() ?? json['designation']?.toString() ?? '',
      createdByRole: json['created_by_role']?.toString() ?? json['rolecode']?.toString() ?? '',
      createdByMobile: json['created_by_mobile']?.toString() ?? json['employee_mobile']?.toString() ?? '',
      suppliedBy: json['supplied_by']?.toString(),
      suppliedByName: json['supplied_by_name']?.toString(),
      suppliedAt: json['supplied_at']?.toString(),
      saleValue: double.tryParse(json['sale_value']?.toString() ?? json['pts_total_amount']?.toString() ?? '0') ?? 0.0,
      outletId: json['outlet_id'] != null ? ((json['outlet_id'] as num?)?.toInt() ?? int.tryParse(json['outlet_id'].toString())) : null,
      outletName: json['outlet_name']?.toString(),
      ownerName: json['owner_name']?.toString(),
      outletMobile: json['outlet_mobile']?.toString(),
      outletAddress: json['outlet_address']?.toString(),
      items: rawItems.map((it) => OutletPobProduct.fromJson(Map<String, dynamic>.from(it))).toList(),
    );
  }
}

class TeamPosRecord {
  final int id;
  final String posType;
  final int outletId;
  final String outletName;
  final String ownerName;
  final String outletMobile;
  final String outletAddress;
  final int productId;
  final String productName;
  final int skuId;
  final String skuDisplayName;
  final int quantity;
  final double skuRetailerPrice;
  final double saleValue;
  final String createdOn;
  final int userId;
  final String employeeName;
  final String employeeId;
  final String roleCode;
  final String designation;
  final String employeeMobile;

  TeamPosRecord({
    required this.id,
    required this.posType,
    required this.outletId,
    required this.outletName,
    required this.ownerName,
    required this.outletMobile,
    required this.outletAddress,
    required this.productId,
    required this.productName,
    required this.skuId,
    required this.skuDisplayName,
    required this.quantity,
    required this.skuRetailerPrice,
    required this.saleValue,
    required this.createdOn,
    required this.userId,
    required this.employeeName,
    required this.employeeId,
    required this.roleCode,
    required this.designation,
    required this.employeeMobile,
  });

  factory TeamPosRecord.fromJson(Map<String, dynamic> json) {
    return TeamPosRecord(
      id: (json['id'] as num?)?.toInt() ?? int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      posType: json['pos_type']?.toString() ?? '',
      outletId: (json['outlet_id'] as num?)?.toInt() ?? int.tryParse(json['outlet_id']?.toString() ?? '0') ?? 0,
      outletName: json['outlet_name']?.toString() ?? '',
      ownerName: json['owner_name']?.toString() ?? '',
      outletMobile: json['outlet_mobile']?.toString() ?? '',
      outletAddress: json['outlet_address']?.toString() ?? '',
      productId: (json['product_id'] as num?)?.toInt() ?? int.tryParse(json['product_id']?.toString() ?? '0') ?? 0,
      productName: json['product_name']?.toString() ?? '',
      skuId: (json['sku_id'] as num?)?.toInt() ?? int.tryParse(json['sku_id']?.toString() ?? '0') ?? 0,
      skuDisplayName: json['sku_displayname']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      skuRetailerPrice: double.tryParse(json['sku_retailerprice']?.toString() ?? '0') ?? 0.0,
      saleValue: double.tryParse(json['sale_value']?.toString() ?? '0') ?? 0.0,
      createdOn: json['created_on']?.toString() ?? '',
      userId: (json['user_id'] as num?)?.toInt() ?? int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      employeeName: json['employee_name']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
      roleCode: json['rolecode']?.toString() ?? '',
      designation: json['designation']?.toString() ?? '',
      employeeMobile: json['employee_mobile']?.toString() ?? '',
    );
  }
}

class OutletActivityFile {
  final int fileId;
  final String fileName;
  final String filePath;

  OutletActivityFile({
    required this.fileId,
    required this.fileName,
    required this.filePath,
  });

  factory OutletActivityFile.fromJson(Map<String, dynamic> json) {
    return OutletActivityFile(
      fileId: (json['file_id'] as num?)?.toInt() ?? int.tryParse(json['file_id']?.toString() ?? '0') ?? 0,
      fileName: json['file_name']?.toString() ?? '',
      filePath: json['file_path']?.toString() ?? json['url']?.toString() ?? '',
    );
  }
}

class OutletActivityRecord {
  final String activityId;
  final String visitId;
  final String userId;
  final String activityDate;
  final String remarks;
  final String activityName;
  final String activityByName;
  final List<OutletActivityFile> files;

  OutletActivityRecord({
    required this.activityId,
    required this.visitId,
    required this.userId,
    required this.activityDate,
    required this.remarks,
    required this.activityName,
    required this.activityByName,
    required this.files,
  });

  factory OutletActivityRecord.fromJson(Map<String, dynamic> json) {
    final rawFiles = json['files'] is List ? json['files'] as List : [];
    return OutletActivityRecord(
      activityId: json['activity_id']?.toString() ?? '',
      visitId: json['visit_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      activityDate: json['activity_date']?.toString() ?? '',
      remarks: json['remarks']?.toString() ?? '',
      activityName: json['activity_name']?.toString() ?? '',
      activityByName: json['activity_by_name']?.toString() ?? '',
      files: rawFiles.map((f) => OutletActivityFile.fromJson(Map<String, dynamic>.from(f))).toList(),
    );
  }
}

class OutletVisitRecord {
  final int visitId;
  final int userId;
  final String? distributorId;
  final String outletId;
  final String visitType;
  final String visitDate;
  final String checkinTime;
  final String? checkoutTime;
  final String? checkinLatitude;
  final String? checkinLongitude;
  final String? checkinAddress;
  final String? checkoutAddress;
  final String? durationMinutes;
  final String? remarks;
  final String visitedByName;
  final String visitedByEmployeeId;
  final String visitedByDesignation;
  final String visitedByRole;
  final String visitedByMobile;
  final List<OutletActivityRecord> activities;

  OutletVisitRecord({
    required this.visitId,
    required this.userId,
    this.distributorId,
    required this.outletId,
    required this.visitType,
    required this.visitDate,
    required this.checkinTime,
    this.checkoutTime,
    this.checkinLatitude,
    this.checkinLongitude,
    this.checkinAddress,
    this.checkoutAddress,
    this.durationMinutes,
    this.remarks,
    required this.visitedByName,
    required this.visitedByEmployeeId,
    required this.visitedByDesignation,
    required this.visitedByRole,
    required this.visitedByMobile,
    required this.activities,
  });

  factory OutletVisitRecord.fromJson(Map<String, dynamic> json) {
    final rawActivities = json['activities'] is List ? json['activities'] as List : [];
    return OutletVisitRecord(
      visitId: (json['visit_id'] as num?)?.toInt() ?? int.tryParse(json['visit_id']?.toString() ?? '0') ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      distributorId: json['distributor_id']?.toString(),
      outletId: json['outlet_id']?.toString() ?? '',
      visitType: json['visit_type']?.toString() ?? 'INDIVIDUAL',
      visitDate: json['visit_date']?.toString() ?? '',
      checkinTime: json['checkin_time']?.toString() ?? '',
      checkoutTime: json['checkout_time']?.toString(),
      checkinLatitude: json['checkin_latitude']?.toString(),
      checkinLongitude: json['checkin_longitude']?.toString(),
      checkinAddress: json['checkin_address']?.toString(),
      checkoutAddress: json['checkout_address']?.toString(),
      durationMinutes: json['duration_minutes']?.toString(),
      remarks: json['remarks']?.toString(),
      visitedByName: json['visited_by_name']?.toString() ?? '',
      visitedByEmployeeId: json['visited_by_employee_id']?.toString() ?? '',
      visitedByDesignation: json['visited_by_designation']?.toString() ?? '',
      visitedByRole: json['visited_by_role']?.toString() ?? '',
      visitedByMobile: json['visited_by_mobile']?.toString() ?? '',
      activities: rawActivities.map((a) => OutletActivityRecord.fromJson(Map<String, dynamic>.from(a))).toList(),
    );
  }
}
