docker inspect -f '{{ range $k, $v := .Config.Labels -}}
{{ $k }}={{ $v }};
{{ end -}}' $cid