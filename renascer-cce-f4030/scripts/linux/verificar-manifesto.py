#!/usr/bin/env python3
"""
Confere uma pasta restaurada contra o manifesto SHA-256 gerado por backup-verify.ps1.

Uso:
    python3 verificar-manifesto.py manifesto.csv /caminho/da/restauracao [--relatorio saida.txt]

Saída:
    - IDÊNTICOS : hash e tamanho batem
    - DIFERENTES: arquivo existe, mas o hash não bate (corrompido/alterado)
    - FALTANDO  : está no manifesto, mas não na restauração
    - EXTRAS    : está na restauração, mas não no manifesto

Código de saída: 0 se tudo idêntico, 1 se houver divergências, 2 em erro de uso.

Projeto Renascer CCE F4030 - Julio Oliver
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import sys
import unicodedata
from pathlib import Path

BLOCO = 1024 * 1024  # lê 1 MiB por vez: não carrega arquivos grandes na RAM


def normalizar(caminho: str) -> str:
    """Barras '/' e Unicode NFC (Windows e Linux podem codificar acentos de forma diferente)."""
    return unicodedata.normalize("NFC", caminho.replace("\\", "/").strip("/"))


def sha256(arquivo: Path) -> str:
    h = hashlib.sha256()
    with arquivo.open("rb") as f:
        for bloco in iter(lambda: f.read(BLOCO), b""):
            h.update(bloco)
    return h.hexdigest()


def ler_manifesto(caminho: Path) -> dict[str, tuple[int, str]]:
    # utf-8-sig remove o BOM que o Export-Csv do PowerShell pode adicionar
    with caminho.open(encoding="utf-8-sig", newline="") as f:
        leitor = csv.DictReader(f)
        obrigatorias = {"Caminho", "Tamanho", "SHA256"}
        if not leitor.fieldnames or not obrigatorias.issubset(leitor.fieldnames):
            raise ValueError(f"Manifesto sem as colunas {sorted(obrigatorias)}")
        return {
            normalizar(l["Caminho"]): (int(l["Tamanho"]), l["SHA256"].strip().lower())
            for l in leitor
        }


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("manifesto", type=Path)
    p.add_argument("pasta", type=Path)
    p.add_argument("--relatorio", type=Path, help="grava a lista de divergências neste arquivo")
    a = p.parse_args()

    # Validação de entradas (lição do incidente 4)
    if not a.manifesto.is_file():
        print(f"[ERRO] Manifesto não encontrado: {a.manifesto}", file=sys.stderr)
        return 2
    if not a.pasta.is_dir():
        print(f"[ERRO] Pasta não encontrada: {a.pasta}", file=sys.stderr)
        return 2

    try:
        esperado = ler_manifesto(a.manifesto)
    except (ValueError, KeyError) as e:
        print(f"[ERRO] Manifesto inválido: {e}", file=sys.stderr)
        return 2

    raiz = a.pasta.resolve()
    presentes = {
        normalizar(str(f.relative_to(raiz))): f
        for f in raiz.rglob("*") if f.is_file()
    }

    identicos, diferentes, faltando = [], [], []
    total = len(esperado)
    for i, (rel, (tamanho, hash_esp)) in enumerate(sorted(esperado.items()), 1):
        print(f"\r[{i}/{total}] verificando...", end="", file=sys.stderr)
        arq = presentes.get(rel)
        if arq is None:
            faltando.append(rel)
        elif arq.stat().st_size != tamanho or sha256(arq) != hash_esp:
            diferentes.append(rel)
        else:
            identicos.append(rel)
    print(file=sys.stderr)

    extras = sorted(set(presentes) - set(esperado))

    print(f"IDÊNTICOS : {len(identicos)}")
    print(f"DIFERENTES: {len(diferentes)}")
    print(f"FALTANDO  : {len(faltando)}")
    print(f"EXTRAS    : {len(extras)}")

    if a.relatorio:
        with a.relatorio.open("w", encoding="utf-8") as r:
            for titulo, lista in (("DIFERENTES", diferentes), ("FALTANDO", faltando), ("EXTRAS", extras)):
                r.write(f"## {titulo} ({len(lista)})\n")
                r.writelines(f"{x}\n" for x in lista)
        print(f"Relatório: {a.relatorio}")

    ok = not diferentes and not faltando
    print("\n[OK] Restauração íntegra." if ok else "\n[ATENÇÃO] Há divergências.")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
