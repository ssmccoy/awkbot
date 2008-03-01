
BEGIN {
    for (d = 0; d <= 255; d++) {
        c = sprintf("%c", d)
        x = sprintf("%02X", d)
        _dec_to_hex[d] = x
        _chr_to_dec[c] = d
        _hex_to_dec[x] = d
        _dec_to_chr[d] = c
    }
}


# Oridinal value for the supplied character
function ord (c) {
    return _chr_to_dec[c]
}

# Character value for the supplied decimal (ordinal)
function chr (d) {
    return _dec_to_chr[d]
}

# Decimal value for the supplied hex string (ordinal)
function dec (x) {
    return _hex_to_dec[toupper(x)]
}

# Hex value for the supplied decimal
function hex (d) {
    return _dec_to_hex[d]
}
