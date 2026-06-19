class Provinsi {
  const Provinsi({required this.id, required this.kode, required this.nama});

  final int id;
  final String kode;
  final String nama;

  factory Provinsi.fromJson(Map<String, dynamic> json) => Provinsi(
        id: json['id'] as int,
        kode: json['kode'] as String? ?? '',
        nama: json['nama'] as String? ?? '',
      );
}

class Kabupaten {
  const Kabupaten({
    required this.id,
    required this.provinsiId,
    required this.kode,
    required this.nama,
  });

  final int id;
  final int provinsiId;
  final String kode;
  final String nama;

  factory Kabupaten.fromJson(Map<String, dynamic> json) => Kabupaten(
        id: json['id'] as int,
        provinsiId: json['provinsiId'] as int,
        kode: json['kode'] as String? ?? '',
        nama: json['nama'] as String? ?? '',
      );
}

class Kecamatan {
  const Kecamatan({
    required this.id,
    required this.kabupatenId,
    required this.kode,
    required this.nama,
  });

  final int id;
  final int kabupatenId;
  final String kode;
  final String nama;

  factory Kecamatan.fromJson(Map<String, dynamic> json) => Kecamatan(
        id: json['id'] as int,
        kabupatenId: json['kabupatenId'] as int,
        kode: json['kode'] as String? ?? '',
        nama: json['nama'] as String? ?? '',
      );
}
