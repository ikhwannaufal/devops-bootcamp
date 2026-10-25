# CI/CD 3: Secrets and Variables

## Objektif hari ni

- **Bezakan** penggunaan **secret** dan **variable** dalam CI/CD
- **Aturkan** CI/CD supaya berjalan tanpa secret terdedah
- **Optimumkan** pengujian dan terbitan dalam satu workflow

---

## Metafor: sambung dapur restoran dari CI/CD 2

Dapur kita dah ada tukang rasa (test) dan palang di pintu keluar (gate). Sekarang soalnya: **maklumat apa yang dapur perlu tahu, dan siapa boleh nampak?**

| Dalam CI/CD | Dalam dapur restoran |
|---|---|
| **Variable** | Papan notis dapur. Semua orang boleh baca, contohnya alamat restoran atau waktu operasi |
| **Secret** | Kunci peti besi atau kod stor. Hanya yang dibenarkan boleh guna |
| **Tulis secret dalam kod** | Tampal kod peti besi pada dinding dapur atau cetak atas menu |
| **History git** | Salinan menu lama yang masih tersimpan. Padam kod dari menu baru pun, menu lama masih ada |
| **Masked (`***`) dalam log** | Buku log dapur yang dihitamkan pada bahagian sulit |
| **Konteks `github`** | Maklumat yang pihak restoran dah sediakan sendiri, macam nama pekerja bertugas dan alamat cawangan |
| **Trigger pull request** | Sesi uji rasa menu baru. Dirasa dulu, belum dihidang kepada pelanggan |
| **Merge ke main** | Menu yang dah lulus, sekarang betul-betul dihidang kepada pelanggan |

---

## Informasi sensitif dalam kod

Dalam workflow, kita biasa letak beberapa nilai konfigurasi dalam blok `env`. Contoh dalam slide ada dua:

| Nilai | Jenis | Boleh nampak? |
|---|---|---|
| `BOARD_URL` | alamat dashboard | Boleh, tak sensitif |
| `SHIPIT_TOKEN` | token untuk hantar laporan | **Mesti disembunyikan** |

### Kalau token ditulis terus dalam kod

- Token **nampak dan kekal dalam history**. Walaupun dibuang kemudian, versi lama masih boleh dilihat
- **Sesiapa boleh menyamar** guna token kita. Dalam contoh slide, orang lain hantar permintaan ke dashboard dengan token tu dan terbitkan **laporan palsu** atas nama kita

Dalam metafor: orang yang jumpa kod peti besi dalam menu lama boleh buat pesanan palsu dan keluarkan barang atas nama kita.

### Prinsip utama

**Informasi sensitif tidak ditulis dalam kod.** Simpan di tempat tersembunyi. Contoh lain yang termasuk kategori ni: **SSH key** dan **kelayakan IAM**.

---

## Variable vs secret

GitHub sediakan dua tempat simpanan berasingan untuk nilai yang kita nak guna dalam workflow.

| | **Variable** | **Secret** |
|---|---|---|
| Konteks | `vars` | `secrets` |
| Cara rujuk | `vars.NAMA` | `secrets.NAMA` |
| Dalam log | **Dipapar penuh** | **Masked** (diganti `***`) |
| Contoh | `BOARD_URL` (alamat) | `SHIPIT_TOKEN` (token) |
| Metafor | Papan notis | Peti besi |

### Cara pilih

- Nilai yang **tak bahaya kalau orang nampak** (alamat, nama, tetapan biasa): guna **variable**
- Nilai yang **bahaya kalau bocor** (token, kata laluan, kunci): guna **secret**

Kalau ragu-ragu, anggap sebagai secret.

---

## Tambah secret dan variable di GitHub

Slide tunjuk versi **ClickOps**, iaitu buat melalui antara muka web (klik-klik), bukan melalui arahan terminal.

### Laluan dalam GitHub

1. Buka repo, pergi ke **Settings**
2. Pilih **Secrets and variables**, kemudian **Actions**
3. Ada dua tab: **Secrets** dan **Variables**

### Tambah secret

- Pilih tab **Secrets**
- Klik **New repository secret**
- Contoh dalam slide: `SHIPIT_TOKEN`
- Ikon mata bergaris menunjukkan nilai disembunyikan

### Tambah variable

- Pilih tab **Variables**
- Klik **New repository variable**
- Contoh dalam slide: `BOARD_URL`
- Ikon mata terbuka menunjukkan nilai boleh dilihat

Kedua-duanya diset pada peringkat **repository**, jadi workflow dalam repo tu boleh rujuk.

---

## Konteks GitHub

Dalam contoh slide, hanya `BOARD_URL` dan `SHIPIT_TOKEN` yang kita sediakan sendiri dalam blok `env`. **Nilai lain datang daripada GitHub.**

### Dua jenis sumber nilai

| Konteks | Siapa sediakan |
|---|---|
| `github` | **GitHub** sediakan automatik |
| `vars` / `secrets` | **Kita** sediakan sendiri |

### Contoh nilai dari konteks `github`

| Dalam workflow | Dalam script | Untuk apa |
|---|---|---|
| `github.actor` | `$GITHUB_ACTOR` | Identiti pengguna GitHub |
| `github.repository` | `$GITHUB_REPOSITORY` | Alamat laman GitHub Pages |

Nilai yang sama boleh dicapai dua cara:

- **Dalam workflow**: guna sintaks konteks (`github.actor`)
- **Dalam script** (contohnya skrip shell yang dipanggil oleh workflow): guna pemboleh ubah persekitaran (`$GITHUB_ACTOR`)

Dalam contoh Amali 2, script laporan guna `GITHUB_ACTOR` sebagai nama di dashboard dan `GITHUB_REPOSITORY` sebagai nama repositori fork.

Dalam metafor: nama pekerja bertugas dan alamat cawangan memang dah dicatat oleh restoran, kita tak payah tulis sendiri. Tapi peti besi dan papan notis, kita yang kena sediakan.

---

## Satu fail, semua jalan serentak

Masalah bila trigger terlalu luas: dalam satu fail workflow yang trigger-nya **push**, **dua job (test dan deploy) akan jalan pada setiap push**, di semua branch.

- Satu trigger, dua tugas, dan kedua-duanya terikat bersama
- Tak kira kita sekadar nak semak kod atau betul-betul nak terbitkan

Tapi keperluan sebenar berbeza ikut situasi:

| Situasi | Yang diperlukan |
|---|---|
| **Buka PR** | **Test** sahaja, tak perlu deploy |
| **Merge ke main** | **Deploy** sahaja, tak perlu test lagi |

**Prinsip: optimumkan tugas, jalan mengikut keperluan.** Jangan buang masa dan sumber untuk benda yang tak perlu.

Dalam metafor: sesi uji rasa menu baru tak perlu terus hidang kepada pelanggan, dan menu yang dah lulus tak perlu diuji rasa berulang kali setiap kali ia dihidang.

---

## Trigger pull request

Untuk capai keperluan di atas, ada tiga perubahan pada workflow.

### 1. Tukar trigger kepada pull request sahaja

- Gantikan trigger lama (push dan dispatch manual) dengan trigger **`pull_request`**
- Workflow sekarang hanya bergerak bila ada aktiviti pada PR

### 2. Tentukan jenis aktiviti PR (`types`)

Test dan deploy berjalan mengikut jenis peristiwa PR:

| Jenis | Bila berlaku |
|---|---|
| `opened` | PR baru dibuka |
| `synchronize` | Ada commit baru ditolak ke PR |
| `reopened` | PR dibuka semula |
| `closed` | PR ditutup (sama ada **merge** atau ditutup tanpa merge) |

### 3. Syarat `if` pada dua-dua job

Setiap job ada syarat sendiri, bergantung sama ada PR sudah **di-merge** atau belum:

| Job | Jalan bila |
|---|---|
| **test** | PR **belum** di-merge |
| **deploy** | PR **sudah** di-merge |

Dalam job deploy, syarat ni digandingkan dengan fungsi `always()`. Penjelasan tambahan: job deploy bergantung pada test melalui `needs`. Bila PR di-merge, test dilangkau, dan biasanya job yang bergantung pada job yang dilangkau pun ikut dilangkau. `always()` memastikan deploy tetap dinilai ikut syaratnya sendiri.

### Hasilnya

- **PR dibuka**: `test` jalan, `deploy` **dilangkau**, belum ada yang diterbitkan
- **PR di-merge ke main**: `test` dilangkau, `deploy` jalan dan laman diterbitkan

---

## Ringkasan

- **Informasi sensitif tak boleh ditulis dalam kod**. Ia kekal dalam history dan sesiapa boleh menyamar guna token yang bocor
- **Variable** untuk nilai biasa (papar penuh dalam log), **secret** untuk nilai sulit (masked `***`)
- Tambah kedua-duanya melalui **Settings, Secrets and variables, Actions**
- Konteks **`github`** disediakan GitHub, manakala **`vars` / `secrets`** kita sediakan sendiri
- Guna trigger **`pull_request`** dengan `types` dan syarat **`if`** supaya **test jalan bila PR dibuka, deploy jalan bila PR di-merge**
- **Optimumkan tugas, jalan mengikut keperluan**
