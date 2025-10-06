{{- define "service" }}
apiVersion: v1
kind: Service
metadata:
  name: service-{{ .name }}
spec:
  type: ClusterIP
  ports:
    - port: {{ .port }}
      protocol: TCP
  selector:
    components: {{ .name }}
{{- end }}

{{- define "deployment" }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deployment-{{ .name }}
spec:
  replicas: {{ .replicas }}
  selector:
    matchLabels:
      components: {{ .name }}
  template:
    metadata:
      name: {{ .name }}
      labels:
        components: {{ .name }}
    spec:
      containers:
        - name: {{ .name }}
          image: {{ .image }}:{{ .version }}
          ports:
            - containerPort: {{ .port }}
          resources:
            limits: {{- toYaml .limits | nindent 14 }}
          {{- if or .env .secret .configmap }}
          env:
          {{- end }}
            {{- /* Обычные переменные */}}
            {{- if .env }}
            {{- range .env }}
            - name: {{ .name }}
              value: {{ .value }}
            {{- end }}
            {{- end }}
            
            {{- /* Переменные из секретов */}}
            {{- if .secret }}
            {{- range .secret }}
            - name: {{ . }}
              valueFrom:
                secretKeyRef:
                  name: secret-all
                  key: {{ . }}
            {{- end }}
            {{- end }}

            {{- /* Переменные из configmap */}}
            {{- if .configmap }}
            {{- range .configmap }}
            - name: {{ . }}
              valueFrom:
                configMapKeyRef:
                  name: configmap-{{ $.name }}
                  key: {{ . }}
            {{- end }}
            {{- end }}
          
          {{- if .pvc }}
          volumeMounts:
            - name: pvc-{{ .name }}
              mountPath: {{ .mountPath }}
          {{- end }}

      {{- if or .pvc .configmap }}
      volumes:
      {{- end }}

        {{- if .configmap }}
        - name: configmap-{{ $.name }}
          configMap:
            name: configmap-{{ $.name }}
            {{- end }}

        {{- if .pvc }}
        - name: pvc-{{ .name }}
          persistentVolumeClaim:
            claimName: pvc-{{ .name }}
            {{- end }}
{{- end }}

{{- define "secret" }}
apiVersion: v1
kind: Secret
metadata:
  name: secret-{{ .name }}
type: Opaque
data:
  {{- range .secrets }}
  {{ .name }}: {{ .value }}
  {{- end }}
{{- end }}

{{- define "pvc"}}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-{{ .name }}
spec:
  accessModes:
    {{- toYaml .pvc.accessModes | nindent 4 }}
  resources:
    requests:
      storage: {{ .pvc.storage }}
{{- end }}