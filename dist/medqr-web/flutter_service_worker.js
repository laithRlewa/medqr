'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"account-deletion.html": "519cf6a0b2837a70bc8e2c115e28f322",
"assets/AssetManifest.bin": "026f094638cbbba6f2bb7dab6b56ece1",
"assets/AssetManifest.bin.json": "8b25e1aff345a33b84beb89ec37ca3dd",
"assets/assets/brand/logo_full.png": "e39d738278111c75a94617fb31a2e75c",
"assets/assets/brand/logo_mark.png": "acf55059e7aa23f9dae56b348785defc",
"assets/assets/brand/wordmark.png": "d4fdb3e226061e063f2aedd7a4e8a215",
"assets/assets/doctors/doctor_ahmed.jpg": "f95a664e47d11fb480100022a377d183",
"assets/assets/doctors/doctor_hussein.jpg": "1e993cf07d258d2c3663bf6de987be50",
"assets/assets/doctors/doctor_nora.jpg": "e848814414becd3ab1c8251013411c0f",
"assets/assets/doctors/doctor_sara.jpg": "6177b82dbcd57141cec8f9443cf67a6d",
"assets/assets/icons/ambulance.png": "eb5c74e45ec10c8f4a4105b624c3d5cd",
"assets/assets/icons/appointment.png": "00152ecc5ff5ce84cc9e83ce39459fb3",
"assets/assets/icons/bandage.png": "0b00ff66d557149dcf495a3e691b1012",
"assets/assets/icons/defibrillator.png": "955409f7e3749411418b20cc57faae2f",
"assets/assets/icons/emergency_call.png": "d1bb5b0147d16d6a9afc471d4de8a8fa",
"assets/assets/icons/emergency_room.png": "dd5637cec4d52251baf0118ae0344aee",
"assets/assets/icons/female_doctor.png": "225cc90355d7d01b182b2d5fb648ffcc",
"assets/assets/icons/fracture.png": "92b9fb43dfbeaa8346cba5e362e16b11",
"assets/assets/icons/gips_leg.png": "8d4b5d3067d9f8c0385e54ef10044f37",
"assets/assets/icons/hospital.png": "4160a618250f3904e46b0048d32526e1",
"assets/assets/icons/infusion.png": "f54b709440f01b66c3e186d173ceb4d0",
"assets/assets/icons/insurance.png": "ce07921e8d16136ddbbac2012105b37e",
"assets/assets/icons/male_doctor.png": "846089baddf5427b53683c5eeae61710",
"assets/assets/icons/medical_app.png": "ecefa7c71539ba781e63b58345b1d0d7",
"assets/assets/icons/medical_bill.png": "f3f042282a87b12bb5c85d9802eda1cc",
"assets/assets/icons/medical_check_up.png": "867805e743d2faba824817b8f680d16e",
"assets/assets/icons/medical_record.png": "fbdff500bd229f7c331a22055f0049ba",
"assets/assets/icons/nurse.png": "7e9d3fb8a592e42ead0a79890431d6ae",
"assets/assets/icons/online_consultation.png": "c6b14b4402f67611c3ea509309829915",
"assets/assets/icons/patient.png": "626eab9d45696ae4a9ada8f01037261c",
"assets/assets/icons/pregnancy.png": "1600ea0365a374f298cc2fc555fa9e88",
"assets/assets/icons/prescription.png": "cc59ef0f828f9cbd7c402f2b722e9732",
"assets/assets/icons/rubber_glove.png": "a4484357b24ede973260ad436a604a3f",
"assets/assets/icons/sfigmomanometer.png": "ea16a91d9861be029b5ac4ee359f80da",
"assets/assets/icons/surgeon.png": "71969296858898040e582d5d296916f3",
"assets/assets/icons/test_tube.png": "8c9e7eaa39d9631641bb31015dd4d54e",
"assets/assets/icons/transfusion.png": "66a670bea0e49c49119e8e5e1a76f7d2",
"assets/assets/icons/waiting_room.png": "61f3b691b77559d7ea508c94de1f8611",
"assets/assets/icons/wheelchair.png": "bc04cc801f6a632287f9e510a3ea9773",
"assets/assets/icons/x_ray.png": "e61a9dbe194aa201af9601e01efdb6c2",
"assets/assets/illustrations/clipboard_meds.png": "1275b753dec33d73c3d97db0aaa0ea50",
"assets/assets/illustrations/dna_clipboard.png": "ac8219057e2af541c44ba10ebf9362d1",
"assets/assets/illustrations/dna_review.png": "242ff5b3030f4ad1f0e09af5aaefaceb",
"assets/assets/illustrations/ecg_review.png": "b51e00ba4f9670f222ad535769fb95c5",
"assets/assets/illustrations/heart_check.png": "e13aa7af7e7aac907a9449ce2670e4e8",
"assets/assets/illustrations/lab_monitor.png": "e7a5ce32fd2f0db76a9c1056487ecfab",
"assets/assets/illustrations/nurse_lab.png": "d2acb3800e7a2ab6bd80f35998fa4ba0",
"assets/assets/illustrations/patient_search.png": "64be94595f0b21275aca10b65581f36c",
"assets/assets/illustrations/profile_visit.png": "9fd5c8c8c16bc23b01a43fd21cc6b83a",
"assets/assets/illustrations/telemedicine.png": "ea0b380625f28910c42e48c554d63be8",
"assets/assets/lottie/doctores-freepik.json": "d35d16f5b1d65cbb0aa518cd9bdb89e2",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "31b2eb962c08609cce3f8a2ff1f83f61",
"assets/NOTICES": "c08ce1970902ec166423a5c18b8d5629",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/flutter_local_notifications_web/web/notifications_service_worker.js": "087634de8a8c1c49d00bcd212bf7feb4",
"assets/packages/flutter_map/lib/assets/flutter_map_logo.png": "208d63cc917af9713fc9572bd5c09362",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01",
"favicon.png": "ac76928f7c2bebd30cfe57e5f93b2ec6",
"firebase-messaging-sw.js": "91eaedbcfc81002a5917cebd3fb7a31f",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"flutter_bootstrap.js": "c397580a512ae0edfb4732ae8d51b75b",
"icons/Icon-192.png": "11a1bc2556b5e45072113fac6bea882e",
"icons/Icon-512.png": "e63471e9ea3f64e7ec4cb62e4846997b",
"icons/Icon-maskable-192.png": "11a1bc2556b5e45072113fac6bea882e",
"icons/Icon-maskable-512.png": "e63471e9ea3f64e7ec4cb62e4846997b",
"index.html": "f30ffdf56e3ef0728d3274a6c0948ab4",
"/": "f30ffdf56e3ef0728d3274a6c0948ab4",
"main.dart.js": "c4d80c1e680838f6331d23f14e6f068f",
"manifest.json": "d38981b5579a94920806bcc2c6b8c98c",
"privacy.html": "c9ead893cc6db28ff38f514b553ac093",
"version.json": "bc7a27608c9a25e205d24ad9078085a8"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
