# CI/CD 4: Push Image ke GHCR dan Auto Deploy

## Objektif hari ni

- **Push** image dashboard ke **GitHub Container Registry (GHCR)**
- **Jalankan** container dashboard di **EC2** secara **manual**
- **Cipta** CI/CD automasi dashboard dengan **self-hosted runner**

---

## Metafor: sambung dapur restoran, sekarang ada cawangan

Sebelum ni semua kerja berlaku dalam satu dapur. Kali ni restoran kita ada **cawangan sebenar** untuk melayan pelanggan, dan soalnya: **macam mana hidangan sampai ke cawangan?**

| Dalam CI/CD | Dalam restoran |
|---|---|
| **Image** | Hidangan siap dibungkus dan dibekukan, tinggal panaskan dan hidang |
| **Registry (GHCR / ECR)** | Gudang pusat yang menyimpan semua bungkusan hidangan |
| **Server (EC2)** | Cawangan restoran. Tempat hidangan sebenarnya dihidang kepada pelanggan |
| **Container** | Hidangan yang sedang dihidang di meja cawangan |
| **Runner GitHub biasa** | Dapur pusat yang GitHub sediakan. Bagus untuk uji rasa dan bungkus, tapi lokasinya jauh dari cawangan |
| **Self-hosted runner** | **Pekerja tetap yang tinggal di cawangan**. Dia sendiri yang ambil bungkusan dari gudang dan hidang |
| **Cara manual** | Chef kena pergi sendiri ke cawangan setiap kali menu berubah, masuk dapur cawangan, dan masak dari awal |
| **Cara automasi** | Chef cuma hantar menu baru ke pusat. Pekerja tetap di cawangan yang uruskan sampai habis |

Idea utama nota ni: **manual = chef bergerak sendiri, automasi = pekerja tetap di cawangan yang bergerak bila dipanggil.**

---

## Image perlu server yang jalankan

Pipeline sebelum ni berhenti pada **menyimpan** image. Tapi image yang tersimpan tak berbuat apa-apa.

| | Peranan |
|---|---|
| **GHCR** (registry) | **Simpan** image |
| **Server** | **Jalankan** image |

Pada peringkat ni kita **belum ada server**. Image perlu satu mesin yang **tarik (pull) dan jalankan**-nya.

Dalam metafor: gudang penuh dengan hidangan beku, tapi belum ada cawangan untuk menghidangnya.

---

## GHCR vs ECR

Kedua-duanya **registry**: tempat untuk **push dan pull image**. Fungsi asasnya sama, yang beza ialah **cara login (auth)**.

| | **GHCR** | **ECR** |
|---|---|---|
| Nama penuh | GitHub Container Registry | Elastic Container Registry (AWS) |
| Siapa punya | GitHub | AWS |
| Kredential | Guna **token GitHub terbina** | **Kredential AWS**, kita urus sendiri |
| Secret baru? | **Tiada** secret baru | Perlu sediakan kredential |
| Langkah awal | Ringkas | Ada langkah tambahan dulu (rujuk Docker 3) |

### Kenapa GHCR lebih senang dalam konteks ni

- Token GitHub **dijana automatik pada setiap run**, jadi tak perlu simpan secret tambahan
- Workflow hanya perlu kebenaran menulis pada package (`packages: write`)

Dalam metafor: gudang GitHub dah kenal pekerja GitHub, jadi tak perlu kad akses baru. Gudang AWS pula perlu kita uruskan sendiri kad aksesnya.

---

## Tambah job build-push ke pipeline

Job baru ni disambung ke pipeline sedia ada. Tujuannya: **bungkus aplikasi jadi image dan hantar ke GHCR**.

### Tiga bahagian penting

| Bahagian | Fungsi |
|---|---|
| **`packages: write`** | Kebenaran untuk push image ke GHCR |
| **login-action** | Setara dengan `docker login`. Login ke registry guna `GITHUB_TOKEN` (rujuk Docker 3) |
| **build-push-action** | Setara dengan `docker build` + `docker push`. Bina image dan terus hantar ke registry (rujuk Docker 2) |

### Perkara untuk ingat

- Job ni guna **`needs`** ke job test, jadi image **hanya dibina kalau gate lulus**. Konsep sama macam CI/CD 2
- Nama image mengikut format: alamat registry (`ghcr.io`) + pemilik + nama repo
- Tag `latest` bermakna versi terkini

Dalam metafor: hidangan hanya dibungkus dan dihantar ke gudang **selepas lulus uji rasa**.

---

## Cara manual: terbit board dengan tangan

Sebelum automasi, kita cuba dulu cara manual supaya faham apa yang akan diautomasikan. Semua dibuat dalam **sesi SSM** di EC2.

### Langkah-langkah

1. **Clone fork** repo ke EC2
2. **Bina dan jalankan** guna Docker Compose. Compose akan bina image terus **di EC2** dan hidupkan container
3. Buka alamat IP awam EC2 dalam browser, **dashboard live**

### Semak dan jaga server

- Semak container dengan `docker ps`. Status **Up**, port 80 dipetakan ke port 3000 dalam container
- Buang cache bina dengan `docker builder prune`, sebab **server t3.micro kecil** dan cache bina boleh makan ruang

### Kelemahan cara manual

- Setiap perubahan, kena **log masuk ke server sendiri** dan ulang langkah
- **Bina image di server kecil** memakan sumber dan ruang
- Mudah terlupa atau tersilap langkah, dan bergantung pada orang yang buat

Dalam metafor: chef kena pergi ke cawangan sendiri setiap kali menu berubah, masak dalam dapur cawangan yang kecil, dan bersihkan dapur lepas tu.

---

## Self-hosted runner

Idea: pasang **runner di EC2 kita sendiri**, supaya GitHub boleh hantar kerja (job) terus ke server tu.

### Macam mana runner sambung

Tiga langkah, dan secara konsep: **daftar runner di EC2, lepas tu GitHub hantar job.**

| Langkah | Apa berlaku |
|---|---|
| **1. New self-hosted runner** | Di GitHub: **Settings → Actions → Runners**. GitHub jana blok Download dan Configure untuk Linux x64 |
| **2. `config.sh` sambung repo** | Di EC2, jalankan konfigurasi guna **URL + token** yang GitHub bagi |
| **3. Servis `svc.sh` install + start** | Jadikan runner sebagai servis, supaya **hidup walaupun sesi ditutup atau server reboot** |

### Perkara penting bila setup

- Salin nilai **URL + token** yang GitHub jana
- Jalankan blok Download sepenuhnya, kemudian **satu baris konfigurasi sahaja**, jangan jalankan `run.sh`
- Tekan Enter untuk semua soalan (guna nilai default) supaya konfigurasi siap
- Jalankan sehingga **`svc.sh` dijana**, kemudian install dan start
- Tanda siap: status runner di repo menunjukkan **Idle** berwarna hijau

### Keselamatan dan kemudahan

- Runner **menyambung keluar** ke GitHub. Jadi **tiada port baharu** perlu dibuka di security group
- User sudah ada dalam **docker group**, jadi `docker compose` boleh jalan **tanpa sudo**
- Dalam workflow, pilih runner kita dengan **`runs-on: self-hosted`**

Dalam metafor: pekerja tetap di cawangan yang **menelefon ibu pejabat sendiri** untuk tanya "ada kerja?", bukan ibu pejabat yang mengetuk pintu cawangan. Sebab tu cawangan tak perlu buka pintu baru untuk orang luar. Dia juga sudah ada kunci stor (docker group), jadi boleh terus ambil barang tanpa minta kebenaran tambahan.

---

## Rantaian penuh: dari satu push sampai EC2

Selepas semua siap, **satu push** boleh menggerakkan keseluruhan rantaian:

**push → gate → bina → GHCR → EC2**

Semuanya hijau dari mula sampai habis, tanpa kita log masuk ke server.

### Dua peranan

Slide tajuk "Rantaian penuh, dua peranan" dengan kenyataan "perisian sama, peranan beza". Bahagian penerangan di bawah slide tak nampak dalam screenshot, jadi bahagian ni **perlu disemak semula dengan slide asal**. Berdasarkan aliran keseluruhan, tafsiran yang munasabah:

- **Peranan pertama**: runner yang menguji, membina, dan menghantar image ke GHCR
- **Peranan kedua**: runner di EC2 yang menarik image dan menjalankannya

---

## Manual vs automasi

| | **Cara manual** | **Cara automasi (self-hosted runner)** |
|---|---|---|
| Siapa gerakkan | Kita log masuk sendiri | GitHub hantar job ke runner |
| Bila berlaku | Bila kita ingat dan sempat | Setiap kali ada push |
| Di mana image dibina | Di EC2 yang kecil | Di runner, kemudian disimpan di GHCR |
| Risiko tersilap | Tinggi, ikut ingatan orang | Rendah, langkah sama setiap kali |
| Gate / test | Mudah terlepas | Dipaksa oleh pipeline |
| Metafor | Chef pergi cawangan setiap kali | Pekerja tetap di cawangan yang bertindak bila dipanggil |

---

## Ringkasan

- **GHCR** dan **ECR** sama-sama registry untuk simpan image, tapi GHCR guna **token GitHub terbina** jadi tiada secret baru
- Job **build-push** guna `packages: write`, **login-action**, dan **build-push-action**, serta bergantung pada job test (gate)
- Registry cuma **simpan**, image tetap perlukan **server untuk jalankan**
- **Cara manual**: clone, compose, buka IP, tapi perlu ulang setiap kali dan membebankan server kecil
- **Self-hosted runner**: daftar di GitHub, sambung dengan `config.sh`, jadikan servis dengan `svc.sh`, dan pilih dengan `runs-on: self-hosted`
- Runner **menyambung keluar**, jadi tiada port baharu di security group
- Hasil akhir: **satu push menggerakkan push, gate, bina, GHCR, EC2** secara automatik
