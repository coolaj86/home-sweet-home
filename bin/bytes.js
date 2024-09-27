#!/usr/bin/env node

let Bytes = {};

Bytes.textEncoder = new TextEncoder();

Bytes.textDecoder = new TextDecoder("utf-8", { fatal: true });

/** @typedef {String} Hex */
/**
 * @param {Hex} hex
 */
Bytes.hexToBytes = function (hex) {
    let bufLen = hex.length / 2;
    let bytes = new Uint8Array(bufLen);

    let i = 0;
    let index = 0;
    let lastIndex = hex.length - 2;
    for (;;) {
        if (i > lastIndex) {
            break;
        }

        let h = hex.substr(i, 2);
        let b = parseInt(h, 16);
        let nan = isNaN(b);
        if (nan) {
            throw new Error(`'${h}' could not be parsed as hex`);
        }
        bytes[index] = b;

        i += 2;
        index += 1;
    }

    return bytes;
};

/**
 * @param {Uint8Array} bytes
 */
Bytes.bytesToHex = function (bytes) {
    /** @type {Array<String>} */
    let hs = [];
    for (let b of bytes) {
        let h = b.toString(16);
        h = h.padStart(2, "0");

        hs.push(h);
    }

    let hex = hs.join("");
    return hex;
};

/** @typedef {String} URLBase64 */
/** @typedef {String} RFCBase64 */
/**
 * Decode Standard or URL-safe Base64 to a Uint8Array
 * @param {URLBase64} urlBase64
 */
Bytes.urlBase64ToBytes = function (urlBase64) {
    let rfcBase64 = urlBase64.replace(/_/g, "/");
    rfcBase64 = rfcBase64.replace(/-/g, "+");
    while (rfcBase64.length % 4 > 0) {
        rfcBase64 += "=";
    }

    let binstr = atob(rfcBase64);
    let bytes = new Uint8Array(binstr.length);
    for (let i = 0; i < binstr.length; i += 1) {
        bytes[i] = binstr.charCodeAt(i);
    }

    return bytes;
};
Bytes.base64ToBytes = Bytes.urlBase64ToBytes;

Bytes.rfcBase64ToBytes = function (rfcBase64) {
    while (rfcBase64.length % 4 > 0) {
        throw new Error(`'${rfcBase64}' could not be parsed as RFC Base64`);
    }
    let binstr = atob(rfcBase64);
    let bytes = new Uint8Array(binstr.length);
    for (let i = 0; i < binstr.length; i += 1) {
        bytes[i] = binstr.charCodeAt(i);
    }

    return bytes;
};

/**
 * Encode Uint8Array bytes as URL-safe Base64
 * @param {Uint8Array} bytes
 * @returns {URLBase64}
 */
Bytes.bytesToUrlBase64 = function (bytes) {
    let binaryString = String.fromCharCode.apply(null, bytes);

    let base64 = btoa(binaryString);

    let urlBase64 = base64.replace(/\+/g, "-");
    urlBase64 = urlBase64.replace(/[/]/g, "_");
    urlBase64 = urlBase64.replace(/=+$/, "");

    return urlBase64;
};

/**
 * Encode Uint8Array bytes as Standard Base64
 * @param {Uint8Array} bytes
 * @returns {RFCBase64}
 */
Bytes.bytesToRfcBase64 = function (bytes) {
    let binaryString = String.fromCharCode.apply(null, bytes);

    let base64 = btoa(binaryString);
    return base64;
};

async function main() {
    let data = process.argv[2];

    let bytes;
    let text;
    let rfcbase64;
    let urlbase64;
    let hex;

    let decoders = [
        {
            from: "hex",
            to: "bytes",
            decode: function () {
                bytes = Bytes.hexToBytes(data);
                hex = data;
                return true;
            },
        },
        {
            from: "rfcbase64",
            to: "bytes",
            decode: function () {
                bytes = Bytes.rfcBase64ToBytes(data);
                rfcbase64 = data;
                return true;
            },
        },
        {
            from: "urlbase64",
            to: "bytes",
            decode: function () {
                bytes = Bytes.urlBase64ToBytes(data);
                urlbase64 = data;
                return true;
            },
        },
        {
            from: "utf8",
            to: "bytes",
            decode: function () {
                bytes = Bytes.textEncoder.encode(data);
                text = data;
                return true;
            },
        },
    ];

    let encoders = [
        {
            from: "bytes",
            to: "utf8",
            encode: function () {
                let text = Bytes.textDecoder.decode(bytes);
                console.info(`Text:       ${text}`);
                return text;
            },
        },
        {
            from: "bytes",
            to: "urlbase64",
            encode: function () {
                let urlbase64 = Bytes.bytesToUrlBase64(bytes);
                console.info(`URL Base64: ${urlbase64}`);
                return urlbase64;
            },
        },
        {
            from: "bytes",
            to: "rfcbase64",
            encode: function () {
                let base64 = Bytes.bytesToRfcBase64(bytes);
                console.info(`RFC Base64: ${base64}`);
                return base64;
            },
        },
        {
            from: "bytes",
            to: "hex",
            encode: function () {
                let hex = Bytes.bytesToHex(bytes);
                console.info(`Hex:        ${hex}`);
                return hex;
            },
        },
    ];

    for (let dec of decoders) {
        try {
            let decoded = dec.decode();
            if (decoded) {
                break;
            }
        } catch (e) {
            // ignore
        }
    }

    console.info();
    if (text) {
        console.info(`Detected: UTF-8`);
    } else if (rfcbase64) {
        console.info(`Detected: RFC Base64`);
    } else if (urlbase64) {
        console.info(`Detected: URL Base64`);
    } else if (hex) {
        console.info(`Detected: Hex`);
    }
    console.info();

    for (let enc of encoders) {
        try {
            enc.encode();
        } catch (e) {
            // ignore
        }
    }
    console.info();
}

main().catch(function (err) {
    console.error("main() error:");
    console.error(err.stack || err);
});

export default Bytes;
