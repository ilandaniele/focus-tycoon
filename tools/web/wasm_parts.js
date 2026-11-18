(function () {
	const WASM_SUFFIX = "index.wasm";
	const originalFetch = window.fetch.bind(window);

	async function fetchJoinedWasm(init) {
		const manifest = await (await originalFetch("index.wasm.parts.json", init)).json();
		const responses = await Promise.all(manifest.parts.map((part) => originalFetch(part, init)));
		if (responses.some((response) => !response.ok)) {
			return new Response(null, { status: 502, statusText: "wasm part missing" });
		}
		const blobs = await Promise.all(responses.map((response) => response.blob()));
		return new Response(new Blob(blobs), {
			headers: { "Content-Type": "application/wasm", "Content-Length": String(manifest.size) },
		});
	}

	window.fetch = function (input, init) {
		const url = typeof input === "string" ? input : input.url;
		return url.split("?")[0].endsWith(WASM_SUFFIX) ? fetchJoinedWasm(init) : originalFetch(input, init);
	};
})();
