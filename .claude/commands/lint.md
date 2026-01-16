# Lint Command

Kodu Python camiasının ve Ruff'ın benimsediği kurallara göre düzenle ve formatla.

## Felsefe

Bu command, PEP 8, Google Python Style Guide ve modern Python best practice'lerini uygular:

1. **Okunabilirlik önce gelir** - Kod, yazılmaktan çok okunur
2. **Tutarlılık** - Tüm kod tabanında aynı stil
3. **Otomatik düzeltme** - Mümkün olan her şeyi otomatik düzelt
4. **Güvenli değişiklikler** - Kod davranışını değiştirme

## Çalıştırılacak Adımlar

### 1. Ruff Format (Black uyumlu)

Önce kodu formatla - bu en temel adım:

```bash
uv run ruff format .
```

Bu adım şunları yapar:
- Tab → 4 boşluk dönüşümü
- Satır uzunluğu normalizasyonu (100 karakter)
- String quote tutarlılığı (çift tırnak)
- Trailing comma ekleme
- Boşluk düzenlemesi

### 2. Ruff Check + Fix (Linting)

Tüm lint kurallarını kontrol et ve otomatik düzelt:

```bash
uv run ruff check . --fix
```

Bu adım şunları düzeltir:
- **F401**: Kullanılmayan import'lar
- **F841**: Kullanılmayan değişkenler
- **I001/I002**: Import sıralaması (isort)
- **W191**: Tab karakterleri
- **W291/W293**: Trailing whitespace
- **UP**: Eski Python syntax'ını modernize et
- **B**: Yaygın bug pattern'lerini düzelt
- **C4**: Daha iyi comprehension'lar
- **SIM**: Kod sadeleştirme

### 3. Relative Import Kontrolü (OpenShift)

OpenShift'te relative import'lar sorun çıkarır:

```bash
grep -rn "^from \." . --include="*.py" && echo "❌ Relative import bulundu - düzeltilmeli!" || echo "✅ Tüm import'lar absolute"
```

### 4. Son Kontrol

Kalan hataları göster (manuel düzeltme gerektirenler):

```bash
uv run ruff check .
```

## Tek Satırda Çalıştırma

```bash
uv run ruff format . && uv run ruff check . --fix && uv run ruff check .
```

## Aktif Kurallar (pyproject.toml)

| Kategori | Kod | Açıklama |
|----------|-----|----------|
| **pycodestyle** | E | PEP 8 hataları |
| **pyflakes** | F | Kullanılmayan import/değişken |
| **warnings** | W | PEP 8 uyarıları (tab, whitespace) |
| **isort** | I | Import sıralaması |
| **pyupgrade** | UP | Modern Python syntax |
| **bugbear** | B | Yaygın bug pattern'leri |
| **comprehensions** | C4 | Daha iyi list/dict comp |
| **simplify** | SIM | Kod sadeleştirme |
| **ruff** | RUF | Ruff özel kuralları |

## Otomatik Düzeltme Tablosu

| Kural | Açıklama | Otomatik? |
|-------|----------|-----------|
| F401 | Kullanılmayan import | ✅ |
| F841 | Kullanılmayan değişken | ✅ |
| I001 | Import sırası yanlış | ✅ |
| W191 | Tab kullanımı | ✅ |
| W291 | Satır sonu boşluk | ✅ |
| UP | Eski syntax (dict() → {}) | ✅ |
| C4 | list(x for x) → [x for x] | ✅ |
| SIM117 | Nested with → single with | ❌ Manuel |
| SIM105 | try/except/pass → suppress | ❌ Manuel |
| RUF012 | ClassVar annotation | ❌ Manuel |
| RUF059 | Unused unpack variable | ❌ Manuel |

## Ignore Edilen Kurallar

| Kural | Sebep |
|-------|-------|
| E501 | Uzun satırlar - SQL, path'ler için kabul edilebilir |
| SIM108 | Ternary operator - bazen daha az okunabilir |
| RUF001/2/3 | Türkçe karakterler kasıtlı |

## Import Sıralaması (PEP 8 + isort)

```python
# 1. Standard library
import os
import sys
from datetime import datetime
from typing import List, Optional

# 2. Third-party packages
import psycopg
from temporalio import workflow

# 3. Local/project imports (src.*)
from src.app_config import app_config
from src.domain.model import Entity
```

## Manuel Düzeltme Gerektiren Durumlar

### SIM117: Nested with statements

```python
# ❌ Ruff uyarısı
with open("a") as f1:
    with open("b") as f2:
        pass

# ✅ Düzeltilmiş
with open("a") as f1, open("b") as f2:
    pass
```

### SIM105: try/except/pass

```python
# ❌ Ruff uyarısı
try:
    do_something()
except SomeError:
    pass

# ✅ Düzeltilmiş
from contextlib import suppress
with suppress(SomeError):
    do_something()
```

### RUF012: Mutable class attributes

```python
# ❌ Ruff uyarısı
class Foo:
    items = []

# ✅ Düzeltilmiş
from typing import ClassVar
class Foo:
    items: ClassVar[list] = []
```

### RUF059: Unused unpacked variable

```python
# ❌ Ruff uyarısı
done, pending = await asyncio.wait(tasks)
# done kullanılmıyor

# ✅ Düzeltilmiş
_, pending = await asyncio.wait(tasks)
```

## noqa Kullanımı

```python
# Tek satır için
import unused_but_needed  # noqa: F401

# Dosya başında (tüm dosya)
# ruff: noqa: E501
```

## Pre-commit Entegrasyonu

`.pre-commit-config.yaml` dosyasına ekle:

```yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.14.0
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
```