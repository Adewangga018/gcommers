public sealed record ProvinsiDto(long Id, string Kode, string Nama);

public sealed record KabupatenDto(long Id, long ProvinsiId, string Kode, string Nama);

public sealed record KecamatanDto(long Id, long KabupatenId, string Kode, string Nama);
