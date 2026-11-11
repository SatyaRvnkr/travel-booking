enum DocumentKind {
  vehicleRc('VEHICLE_RC'),
  drivingLicense('DRIVING_LICENSE'),
  profilePhoto('PROFILE_PHOTO'),
  aadhar('AADHAAR'),
  pan('PAN');

  const DocumentKind(this.apiValue);

  /// Value sent to backend (`documentType` in Postman).
  final String apiValue;
}

enum DocumentSide {
  front('front'),
  back('back'),
  single('front');

  const DocumentSide(this.apiValue);

  /// Side sent to backend as in Postman (`front` / `back`).
  final String apiValue;
}

String documentSideKey(DocumentKind kind, DocumentSide side) =>
    '${kind.apiValue}_${side.name.toUpperCase()}';
