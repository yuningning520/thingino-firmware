/* ZONE MAPPER */
let rois = [
	[0,0,50,50],
	[300,300,100,100]
];

function reorderCoords(ar) {
	let numArray = new Float64Array(ar);
	return numArray.sort();
}

function normalizeZone(x, y, w, h) {
	if (w < 0) {
		w = -(w);
		x = x - w;
	}
	if (h < 0) {
		h = -(h);
		y = y - h;
	}
	return [x,y,w,h];
}

function enableZoneMapper() {
	MinZoneHeight = 30;
	MinZoneWidth = 30;
	let mode = 'draw';

	function loadZones() {
		rois.forEach(z => {
			ctx.fillRect(z[0], z[1], z[2], z[3]);
		});
	}

	function resetZones() {
		ctx.reset();
		loadZones();
	}

	let sx = 0;
	let sy = 0;

	const frame = $('#frame');
	const fw = frame.clientWidth;
	const fh = frame.clientHeight;

	const cv = document.createElement('canvas');
	cv.width = fw;
	cv.height = fh;
	cv.id = 'roi';
	cv.classList.add('position-absolute', 'top-0');
	frame.append(cv);

	const bound = cv.getBoundingClientRect();
	const bl = bound.left;
	const bt = bound.top;
	const ccl = cv.clientLeft;
	const cct = cv.clientTop;

	const ctx = cv.getContext('2d');
	resetZones();

	cv.addEventListener('mousedown', ev => {
		const x = Math.ceil(ev.clientX - bl - ccl);
		const y = Math.ceil(ev.clientY - bt - cct);
		console.log("Mouse button pressed at (" + x + "," + y + ")");

		if (ev.shiftKey) {
			console.log("Shift key is pressed");
			let index = 0;
			rois.forEach(z => {
				console.log("Zone " + index + " " + z);
				if (x > z[0] && x < (z[0] + z[2]) && y > z[1] && x < (z[1] + z[3])) {
					console.log("Click is within this zone!");
					rois.splice(index, 1);
					resetZones();
				}
				index = index + 1;
			});
			return;
		} else {
			sx = x;
			sy = y;
		}
		ev.preventDefault();
	});

	cv.addEventListener('mousemove', ev => {
		if (ev.buttons != 1) return;
		if (ev.shiftKey) return;

		const w = Math.ceil(ev.clientX - bl - ccl - sx);
		const h = Math.ceil(ev.clientY - bt - cct - sy);
		resetZones();

		if (Math.abs(w) < MinZoneWidth || Math.abs(h) < MinZoneHeight) {
			ctx.strokeStyle = "red";
		} else {
			ctx.strokeStyle = "white";
		}
		ctx.lineWidth = 5;
		ctx.rect(sx, sy, w, h);
		ctx.stroke();
	});

	cv.addEventListener('mouseup', ev => {
		if (ev.shiftKey) {
			console.log("Shift key is pressed. Exiting.");
			return;
		}

		const x = Math.ceil(ev.clientX - bl - ccl);
		const y = Math.ceil(ev.clientY - bt - cct);
		console.log("Mouse button released at (" + x + "," + y + ")");

		const w = x - sx;
		const h = y - sy;
		console.log("Zone size: " + w + "x" + h);

		if (Math.abs(w) < MinZoneWidth) {
			console.log("Width is less than " + MinZoneWidth + "px");
			resetZones();
			return;
		} else if (Math.abs(h) < MinZoneHeight) {
			console.log("Height is less than " + MinZoneHeight + "px");
			resetZones();
			return;
		} else {
			resetZones();
			ctx.fillStyle = "red";
			ctx.fillRect(sx, sy, w, h);
			rois.push(normalizeZone(sx, sy, w, h));
		}
	})
}

$('#zonemapper').addEventListener('click', () => {
	enableZoneMapper();
})
