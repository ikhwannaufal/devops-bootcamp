# CI/CD 2: Build + Gate

## Objektif hari ni

- **Tambah** komponen CI/CD untuk halang kod rosak
- **Buktikan** kod rosak memang dihalang daripada sampai ke produksi
- **Atur** komponen CI/CD supaya automasi lebih mudah diguna semula dan dikembangkan

---

## Metafor: sambung dapur restoran dari CI/CD 1

Kat CI/CD 1 kita dah ada dapur automatik: pesanan masuk (push), dapur masak, hidangan terus dihantar ke meja pelanggan (lancar).

Masalahnya, **tak ada sesiapa rasa dulu sebelum hidang**. Kali ni kita tambah **pengawal mutu (QC)** kat pintu keluar dapur.

| Dalam CI/CD | Dalam dapur restoran |
|---|---|
| **Test** | Tukang rasa. Rasa masakan sebelum keluar dari dapur |
| **Gate** | Palang di pintu keluar dapur. Lulus rasa, palang naik. Gagal, palang kekal tutup |
| **Test hijau** | Lulus QC, hidangan boleh dihantar |
| **Test merah** | Gagal QC, hidangan tak boleh keluar |
| **Baiki + push semula** | Chef betulkan masakan, hantar balik untuk dirasa semula |
| **Job** | Satu stesen kerja dengan meja dan peralatan sendiri |
| **Runner / instance** | Meja kerja bersih yang disediakan untuk satu stesen |
| **`needs`** | Stesen hidang tak boleh mula selagi stesen QC belum lulus |

---

## Masalah: konfigurasi rosak terlepas

Dalam CI/CD 1, **setiap push terus dibina dan dilancarkan**. Nampak bagus, tapi ada lubang besar.

Contoh dalam slide: fail konfigurasi `ship.config.json` ada nilai `color` yang tak betul.

- Workflow di Actions tetap **hijau**
- Laman **dilancarkan ke produksi tanpa sebarang amaran**
- Tiada sesiapa tahu ada masalah sampai pengguna nampak sendiri

**Hijau tak bermakna betul.** Hijau cuma bermakna tiada step yang gagal. Kalau kita tak pernah suruh pipeline semak benda tu, dia takkan semak.

Kesimpulan: perlu satu **gate** untuk halang.

Dalam metafor: masakan salah rasa tetap dihantar sebab tiada tukang rasa. Dapur nampak lancar, tapi pelanggan yang tanggung akibatnya.

---

## Step test jadi gate

Ada dua cara nak pastikan konfigurasi betul:

| | Semak dengan mata | Semak dengan step `test` |
|---|---|---|
| Cara | Baca fail konfigurasi sendiri | Pipeline jalankan arahan test automatik |
| Masalah / kelebihan | Manusia boleh terlepas pandang | Semakan **sama** pada setiap push |

Semak dengan mata bergantung pada tumpuan dan mood kita hari tu. Semak dengan test pula konsisten, tak penat, tak lupa.

### Arahan test bergantung pada ekosistem

Bukan npm je. Setiap ekosistem ada arahan test sendiri:

| Ekosistem | Arahan |
|---|---|
| Node (npm) | `npm run test` |
| Python | `pytest` |
| PHP | `vendor/bin/phpunit` |
| .NET | `dotnet test` |
| Java (Maven) | `mvn test` |

Konsep sama, cuma arahan lain. Pipeline tak kisah bahasa apa, dia cuma tengok sama ada arahan tu **berjaya atau gagal**.

---

## Test merah hentikan pipeline

Pipeline kita sekarang ada empat peringkat: **Install → Test → Build → Deploy**.

Bila test **merah**:

- Arahan test pulangkan kod keluar (exit code) **1**, tanda gagal
- Step tu dianggap gagal, jadi **langkah selepasnya berhenti dan tak diteruskan**
- Build dan Deploy tak akan jalan langsung

Ini yang buat test berfungsi sebagai gate. Kita tak perlu tulis logik "kalau gagal jangan lancar", sebab GitHub Actions dah berhenti sendiri bila satu step gagal.

Dalam metafor: tukang rasa kata "tak sedap", palang kekal tutup, hidangan tak sampai meja.

---

## Gelung merah ke hijau

Aliran kerja bila ada gate:

1. **Push** kod
2. **Test** jalan automatik
3. Kalau **hijau**, terus ke **Lancar**
4. Kalau **merah**, kita **baiki**, lepas tu **push semula**, dan kitaran ulang dari langkah 2

Gate sahkan **setiap push** sebelum lancar. Kod rosak berpusing dalam gelung ni je dan tak akan sampai produksi. Kitaran ni dipanggil **gelung merah ke hijau** (red-green loop).

---

## Satu job atau dua job

Nak letak test dan deploy dalam satu job, atau pecah jadi dua?

### Satu job

- Satu job `test` yang ada semua step: pasang, uji, bina, lancar
- Semua jalan atas **satu runner**
- Ringkas dan senang faham

### Dua job

- Job `test`: pasang, uji
- Job `deploy`: bina, lancar
- Job deploy guna **`needs`**, bermaksud ia hanya jalan lepas job test berjaya
- Setiap job ada **runner sendiri**

### Bila nak pecah?

**Pecah job bila perlu kerja selari atau runner berbeza.**

Contohnya, kalau ada beberapa kerja bebas yang boleh jalan serentak, atau satu kerja perlukan jenis mesin lain. Kalau tak ada keperluan tu, satu job pun dah cukup.

Dalam metafor: satu stesen buat semua kerja, atau dua stesen berasingan dan stesen hidang hanya mula bila stesen QC dah lulus.

---

## Setiap job guna instance baru

Perkara penting bila pecah job:

- Setiap job, runner cipta **instance baru** (mesin segar)
- Antara dua job **tiada kongsi fail**
- Bila job tamat, **instance dibuang**
- Jadi setiap job kena **pasang semula sendiri**: checkout kod, sediakan Node, pasang dependency, baru buat kerja utama (test atau build)

Dua job = dua mesin berasingan. Job deploy tak boleh "guna balik" apa yang job test dah pasang.

Kesannya, kita ulang beberapa step yang sama dalam kedua-dua job. Itu harga untuk asingkan kerja. Kalau kerja kecil, satu job mungkin lebih jimat masa.

Dalam metafor: setiap stesen dapat meja kerja yang bersih. Bahan dan peralatan stesen QC tak dibawa ke stesen hidang, jadi stesen hidang kena sediakan bahan sendiri. Habis kerja, meja dibersihkan dan dibuang.

---

## Ringkasan

- **Masalah:** pipeline hijau tak jamin kod betul. Konfigurasi rosak boleh terlepas ke produksi tanpa amaran
- **Penyelesaian:** tambah step **test** sebagai **gate** sebelum build dan deploy
- **Test merah** (exit code 1) menghentikan langkah seterusnya, jadi kod rosak tak sampai produksi
- **Gelung merah ke hijau:** push, test, kalau merah baiki dan push semula, kalau hijau lancar
- Arahan test lain-lain ikut ekosistem, tapi konsepnya sama
- **Satu job** untuk ringkas, **dua job** bila perlu kerja selari atau runner berbeza, dengan `needs` untuk susun urutan
- **Setiap job guna instance baru**, tiada kongsi fail, dan kena pasang semula sendiri
