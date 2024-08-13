#!/usr/bin/haserl
<%in _common.cgi %>
<%in _icons.cgi %>
<%
token="$(cat /run/prudynt_websocket_token)"
page_title="Camera preview"

for i in "ispmode"; do
	eval "$i=\"$(/usr/sbin/imp-control $i)\""
done
%>
<%in _header.cgi %>

<div class="row preview">
	<div class="col-lg-9 mb-3">
		<div id="frame" class="position-relative ratio ratio-16x9 mb-2">
			<div class="smpte"><div class="bar1"></div><div class="bar2"></div><div class="bar3"></div></div>
			<img id="preview" class="img-fluid" alt="Image: Preview"></img>
			<%in _motors.cgi %>
		</div>
		<p class="small text-body-secondary"><span id="playrtsp"></span>
<% if [ "true" = "$has_motors" ]; then %>
			Move the cursor over the center of the preview image to reveal the motor controls.<br>
			Use a single click for precise positioning, double click for coarse, long-distance movement.
<% fi %>
		</p>
	</div>
	<div class="col-lg-1" style="width:4em">
		<div class="btn-group-xl-vertical" role="group" aria-label="Day/Night controls">
			<input type="checkbox" class="btn-check" name="daynight" id="daynight" value="1"<% checked_if $daynight 1 %>>
			<label class="btn btn-dark border mb-2" for="daynight" title="Night mode"><%= $icon_moon %></label>
			<input type="checkbox" class="btn-check" name="ispmode" id="ispmode" value="1"<% checked_if $ispmode 1 %>>
			<label class="btn btn-dark border mb-2" for="ispmode" title="Color mode"><%= $icon_color %></label>
			<input type="checkbox" class="btn-check" name="ircut" id="ircut" value="1"<% checked_if $ircut 1 %><% get gpio_ircut >/dev/null || echo " disabled" %>>
			<label class="btn btn-dark border mb-2" for="ircut" title="IR filter"><%= $icon_ircut %></label>
			<input type="checkbox" class="btn-check" name="ir850" id="ir850" value="1"<% checked_if $ir850 1 %><% get gpio_ir850 >/dev/null || echo " disabled" %>>
			<label class="btn btn-dark border mb-2" for="ir850" title="IR LED 850 nm"><%= $icon_ir850 %></label>
			<input type="checkbox" class="btn-check" name="ir940" id="ir940" value="1"<% checked_if $ir940 1 %><% get gpio_ir940 >/dev/null || echo " disabled" %>>
			<label class="btn btn-dark border mb-2" for="ir940" title="IR LED 940 nm"><%= $icon_ir940 %></label>
			<input type="checkbox" class="btn-check" name="white" id="white" value="1"<% checked_if $white 1 %><% get gpio_white >/dev/null || echo " disabled" %>>
			<label class="btn btn-dark border mb-2" for="white" title="White LED"><%= $icon_white %></label>
			<input type="checkbox" class="btn-check" name="vflip" id="vflip" value="1">
			<label class="btn btn-dark border mb-2" for="vflip" title="Flip vertically"><%= $icon_flip %></label>
			<input type="checkbox" class="btn-check" name="hflip" id="hflip" value="1">
			<label class="btn btn-dark border mb-2" for="hflip" title="Flip horizontally"><%= $icon_flop %></label>
		</div>
	</div>
	<div class="col-lg-2">
		<div class="gap-2">
			<div class="mb-1">
				<a href="image.cgi" target="_blank" class="form-control btn btn-primary text-start">Save image</a>
			</div>
			<div class="input-group mb-1">
				<button class="form-control btn btn-primary text-start" type="button" data-sendto="email">Email</button>
				<div class="input-group-text"><a href="plugin-send2email.cgi" title="Email settings"><%= $icon_gear %></a></div>
			</div>
			<div class="input-group mb-1">
				<button class="form-control btn btn-primary text-start" type="button" data-sendto="ftp">FTP</button>
				<div class="input-group-text"><a href="plugin-send2ftp.cgi" title="FTP Storage settings"><%= $icon_gear %></a></div>
			</div>
			<div class="input-group mb-1">
				<button class="form-control btn btn-primary text-start" type="button" data-sendto="telegram">Telegram</button>
				<div class="input-group-text"><a href="plugin-send2telegram.cgi" title="Telegram bot settings"><%= $icon_gear %></a></div>
			</div>
			<div class="input-group mb-1">
				<button class="form-control btn btn-primary text-start" type="button" data-sendto="mqtt">MQTT</button>
				<div class="input-group-text"><a href="plugin-send2mqtt.cgi" title="MQTT settings"><%= $icon_gear %></a></div>
			</div>
			<div class="input-group mb-1">
				<button class="form-control btn btn-primary text-start" type="button" data-sendto="webhook">WebHook</button>
				<div class="input-group-text"><a href="plugin-send2webhook.cgi" title="Webhook settings"><%= $icon_gear %></a></div>
			</div>
			<div class="input-group mb-1">
				<button class="form-control btn btn-primary text-start" type="button" data-sendto="yadisk">Yandex Disk</button>
				<div class="input-group-text"><a href="plugin-send2yadisk.cgi" title="Yandex Disk bot settings"><%= $icon_gear %></a></div>
			</div>
<% if [ "$debug" -gt 3 ]; then %>
			<button id="zonemapper" class="form-control btn btn-secondary" type="button">Zone Mapper</button>
<% fi %>
		</div>
	</div>
</div>

<script src="/a/imp-config.js"></script>
<script>
const network_address = "<%= $network_address %>";

<% [ "true" != "$email_enabled"    ] && echo "\$('button[data-sendto=email]').disabled = true;" %>
<% [ "true" != "$ftp_enabled"      ] && echo "\$('button[data-sendto=ftp]').disabled = true;" %>
<% [ "true" != "$mqtt_enabled"     ] && echo "\$('button[data-sendto=mqtt]').disabled = true;" %>
<% [ "true" != "$webhook_enabled"  ] && echo "\$('button[data-sendto=webhook]').disabled = true;" %>
<% [ "true" != "$telegram_enabled" ] && echo "\$('button[data-sendto=telegram]').disabled = true;" %>
<% [ "true" != "$yadisk_enabled"   ] && echo "\$('button[data-sendto=yadisk]').disabled = true;" %>

$$("button[data-sendto]").forEach(el => {
	el.addEventListener("click", ev => {
		ev.preventDefault();
		if (!confirm("Are you sure?")) return false;
		const tgt = ev.target.dataset["sendto"];
		xhrGet("/x/send.cgi?to=" + tgt);
	});
});

let last_frame_ts = null;

function updatePreview(data) {
	const blob = new Blob([data], {type: 'image/jpeg'});
	const url = URL.createObjectURL(blob);
	jpg.src = url;
}

const jpg = $("#preview");

let ws = new WebSocket('ws://' + document.location.hostname + ':8089?token=<%= $token %>');
ws.onopen = () => {
	console.log('WebSocket connection opened');
	ws.send('{"image":{"hflip":null,"vflip":null},"rtsp":{"username":null,"password":null,"port":null}}');
}
ws.onclose = () => { console.log('WebSocket connection closed'); }
ws.onerror = (error) => { console.error('WebSocket error', error); }
ws.onmessage = (event) => {
	if (typeof event.data === 'string') {
		console.log(event.data);

		const msg = JSON.parse(event.data);
		const time = new Date(msg.date);
		const timeStr = time.toLocaleTimeString();

		if (msg.image.hflip) $('#hflip').checked = msg.image.hflip;
		if (msg.image.vflip) $('#vflip').checked = msg.image.vflip;

		if (msg.rtsp)
			if (msg.rtsp.username && msg.rtsp.password && msg.rtsp.port)
				$('#playrtsp').innerHTML = "RTSP player mpv --profile=low-latency rtsp://" +
					msg.rtsp.username + ":" + msg.rtsp.password + "@" +
					document.location.hostname + ":" + msg.rtsp.port + "/ch0";

	} else if (event.data instanceof ArrayBuffer) {
		const now = Date.now();
		if (last_frame_ts != null) {
			const frame_rate = Math.round(1000/(Date.now() - last_frame_ts));
			$("#frame_rate").innerText = frame_rate;
		}
		last_frame_ts = now;

		updatePreview(event.data);
	}
	ws.binaryType = 'arraybuffer';
	ws.send('{"action":{"capture":null}}');
}

$('#hflip').addEventListener('change', ev => ws.send('{"image":{"hflip":' + ev.target.checked + '},"action":{"save_config":null}}'));
$('#vflip').addEventListener('change', ev => ws.send('{"image":{"vflip":' + ev.target.checked + '},"action":{"save_config":null}}'));

$("#daynight")?.addEventListener("change", ev => {
	if (ev.target.checked) {
		$("#ispmode").checked = false;
		$("#ircut").checked = false;
		["ir850", "ir940", "white"].forEach(n => $("#" + n).checked = true)
		mode = "night";
	} else {
		$("#ispmode").checked = true;
		$("#ircut").checked = true;
		["ir850", "ir940", "white"].forEach(n => $("#" + n).checked = false)
		mode = "day";
	}
});
</script>

<style>
#controls div.buttons { background: #88888888; visibility: hidden; width: 100%; height: 100%; }
#controls:hover div.buttons { visibility: visible; }
</style>

<%in _footer.cgi %>
