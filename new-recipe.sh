#!/bin/sh
# Script para criar estrutura de recipe de programa

# ===== CONFIGURAÇÕES =====
REPO=${REPO:-$PWD/repo}          # diretório base do repositório
SOURCES=${SOURCES:-$PWD/sources} # diretório de sources
CATEGORIES="base x11 extras desktop"

mkdir -p "$REPO" "$SOURCES"

# ===== FUNÇÕES =====
ask_category() {
    echo "Escolha a categoria:"
    select cat in $CATEGORIES; do
        if [ -n "$cat" ]; then
            CATEGORY=$cat
            break
        fi
    done
}

create_recipe() {
    pkgname=$1
    version=$2
    url=$3
    shift 3
    patches="$@"

    if [ -z "$pkgname" ] || [ -z "$version" ] || [ -z "$url" ]; then
        echo "Uso: $0 <nome> <versão> <url-source> [patch1 patch2 ...]"
        exit 1
    fi

    ask_category

    pkgdir="$REPO/$CATEGORY/${pkgname}-$version"
    mkdir -p "$pkgdir"

    recipe="$pkgdir/${pkgname}.recipe"

    if [ -f "$recipe" ]; then
        echo "[!] Recipe já existe: $recipe"
        exit 1
    fi

    archive=$(basename "$url")

    # monta lista de patches (nomes só)
    patch_files=""
    for p in $patches; do
        patch_files="$patch_files $(basename "$p")"
    done

    cat > "$recipe" <<EOF
# Recipe para $pkgname-$version
# Categoria: $CATEGORY

NAME=$pkgname
VERSION=$version
SOURCE_URL="$url"
SOURCE_ARCHIVE="$archive"
PATCHES="$patch_files"
DEPENDS=""

# ===== FUNÇÕES DISPONÍVEIS =====

pre_build() { true; }
unpack() { tar -xf "\$SOURCE_ARCHIVE" && cd "\$NAME-\$VERSION"; }
apply_patches() { for p in \$PATCHES; do patch -p1 < "../\$p"; done; }
configure() { ./configure --prefix=/usr; }
build() { make -j\$(nproc); }
check() { make check || true; }
install() { make DESTDIR="\$DESTDIR" install; }
post_install() { true; }
post_remove() { true; }
EOF

    echo "[+] Recipe criada em: $recipe"

    # baixa source
    echo "[+] Baixando source para $SOURCES..."
    wget -c -P "$SOURCES" "$url"

    # baixa patches (se existirem)
    for p in $patches; do
        fname=$(basename "$p")
        echo "[+] Baixando patch: $p"
        wget -c -P "$SOURCES" "$p"
        echo "[+] Copiando patch para o pacote..."
        cp "$SOURCES/$fname" "$pkgdir/"
    done
}

# ===== MAIN =====
create_recipe "$@"
