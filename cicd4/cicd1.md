# GitHub Actions

## Objektif hari ni

- Faham macam mana aliran **CI/CD** berjalan dan apa bahagian dalam satu **pipeline**
- Tulis **workflow GitHub Actions** pertama, then cetuskan (trigger) dengan `git push`
- Terbitkan laman ke **GitHub Pages** secara automatik setiap kali push

---

## Metafor: GitHub Actions ni macam dapur restoran

Senang nak faham kalau bayangkan satu restoran yang semua kerja dapur dah diautomasikan.

| Dalam GitHub Actions | Dalam dapur restoran |
|---|---|
| **Trigger** (`on`) | Pesanan pelanggan masuk. Bila ada pesanan, dapur mula kerja |
| **Workflow** | Buku resipi untuk satu hidangan, dari bahan mentah sampai siap |
| **Job** | Satu stesen kerja (stesen potong, stesen goreng, stesen hias) |
| **Step** | Satu langkah dalam resipi ("potong bawang", "tumis", dll.) |
| **Runner** (`runs-on`) | Dapur + tukang masak yang GitHub sediakan percuma. Kita tak payah beli dapur sendiri |
| **`uses`** (action orang lain) | Guna sos atau pes siap beli. Orang lain dah sediakan, kita guna je |
| **`run`** (arahan shell) | Masak sendiri, kita tentukan apa nak buat |
| **Artifact** | Hidangan yang dah siap dan dibungkus, tunggu nak dihantar |
| **Deploy / terbit** | Hantar hidangan tu ke meja pelanggan |
| **Permissions** | Kebenaran. Pelayan tak boleh sesuka hati hidang kalau tak diberi kuasa |

Idea utama: sekali tulis resipi, lepas tu setiap kali ada pesanan (push), dapur masak sendiri tanpa kita kacau.

---

## Anatomi GitHub Actions

Semuanya ditulis dalam satu fail `.yaml`, disusun berlapis:

**workflow › job › step**

- **Workflow**: keseluruhan automasi. Fail disimpan dalam folder `.github/workflows/`
- **Job**: satu kumpulan kerja
- **Step**: satu arahan dalam job

### Runner

Mesin yang GitHub sediakan percuma untuk jalankan job kita. Kita cuma pilih jenis mesin (contohnya Ubuntu), selebihnya GitHub urus.

### Trigger

Penentu bila workflow nak mula. Dua contoh biasa:

- **push**: jalan automatik setiap kali ada push
- **workflow_dispatch**: jalan bila kita tekan butang secara manual

---

## Bentuk fail workflow

Format fail ialah **YAML**, dah biasa dari Docker 4. Peraturan asas yang perlu ingat:

- Indentasi guna **space** (bukan tab)
- Senarai guna tanda `-`

Setiap workflow ada struktur yang sama:

| Bahagian | Maksud |
|---|---|
| `workflow` | satu fail |
| `name` | nama workflow |
| `on` | trigger |
| `job` | kumpulan kerja |
| `runs-on` | runner |
| `step` | satu arahan |

Rujukan lanjut ada kat dokumen rasmi GitHub Actions.

---

## Padanan: workflow, job, step

- **Workflow** = keseluruhan automasi (satu fail `.yaml`)
- **Job** = satu kumpulan kerja atas satu runner
- **Step** = satu arahan di dalam job

Ada dua cara untuk tulis step:

- **`uses`**: guna action orang lain yang dah siap dibuat
- **`run`**: jalankan arahan shell terus

---

## Aliran bina + terbit (Amali 4)

Tujuan amali ni: tambah peringkat **bina** dan **terbit** supaya laman dihantar ke GitHub Pages secara automatik.

Persediaan awal: aktifkan GitHub Pages untuk repo (boleh dibuat melalui API GitHub CLI), dan set supaya Pages guna workflow sebagai sumber terbitan.

Urutan kerja dalam pipeline:

1. **Ambil kod**: kod repo disalin ke runner
2. **Sedia Node**: runtime Node dipasang
3. **Pasang dependency**: pakej dimuat turun
4. **Bina laman**: hasilkan folder `dist`
5. **Bungkus dist**: jadikan **artifact** di GitHub
6. **Terbit ke Pages**: hantar artifact ke GitHub Pages (sama macam cara kat GitHub 2)

Dalam metafor dapur: ambil bahan, sediakan peralatan, siapkan bahan mentah, masak, bungkus, hantar.

---

## Pipeline pecah (masalah biasa)

Pipeline ada tiga peringkat besar: **Source → Build → Deploy**.

Dalam contoh slide, Source dan Build berjaya, tapi **Deploy gagal** dengan mesej error pasal `GITHUB_TOKEN` tak ada kebenaran `pages: write`.

Pengajaran:

- Kalau **satu step gagal, pipeline terus berhenti**. Peringkat selepas tu tak akan jalan
- Untuk terbit ke Pages, workflow perlu ada blok **`permissions`** yang bagi kebenaran menulis ke Pages
- Error ni boleh semak kat tab **Actions** dalam repo

Metafor: hidangan dah siap dimasak dan dibungkus, tapi pelayan tak dibenarkan hantar ke meja. Masakan elok pun tak sampai pelanggan.

---

## Ringkasan sesi

- Boleh terangkan aliran CI/CD dan bahagian satu pipeline
- Dah tulis workflow GitHub Actions pertama dan cetuskan dengan push
- Dah terbitkan laman ke GitHub Pages automatik setiap push
