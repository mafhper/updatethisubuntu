# Sistema de Manutenção Ubuntu

Interface web elegante para execução e monitoramento do script de manutenção do sistema Ubuntu.

## 📋 Requisitos

- Node.js 18+ 
- Python 3.8+
- Ubuntu/Debian (para o script de manutenção)
- Permissões sudo para o usuário que executará o backend

## 🛠 Estrutura do Projeto

```
sistema-manutencao/
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   │   └── SystemMaintenanceUI.jsx
│   │   └── App.jsx
│   ├── package.json
│   └── vite.config.js
├── backend/
│   ├── app.py
│   ├── script_wrapper.py
│   └── script-manutencao.sh
└── README.md
```

## ⚙️ Configuração do Backend

1. Crie um ambiente virtual Python:
```bash
python -m venv venv
source venv/bin/activate  # Linux/Mac
```

2. Instale as dependências:
```bash
pip install fastapi uvicorn python-socketio asyncio aiofiles
```

3. Crie o arquivo `backend/script_wrapper.py`:
```python
import asyncio
import subprocess
import re
from datetime import datetime

class ScriptExecutor:
    def __init__(self, socketio):
        self.socketio = socketio
        self.process = None
        
    async def parse_output(self, line):
        # Padrões para reconhecer diferentes tipos de mensagens
        step_pattern = r"== \[ (\d{2}:\d{2}:\d{2}) \] (.+)"
        download_pattern = r"Dados baixados: \+(.+)B"
        space_pattern = r"Espaço liberado: -(.+)B"
        
        # Análise da linha de saída
        if match := re.search(step_pattern, line):
            time, step = match.groups()
            return {
                "type": "step",
                "time": time,
                "message": step
            }
        elif match := re.search(download_pattern, line):
            size = match.group(1)
            return {
                "type": "download",
                "size": size
            }
        elif match := re.search(space_pattern, line):
            size = match.group(1)
            return {
                "type": "space",
                "size": size
            }
        elif "ATENÇÃO: O sistema precisa ser reiniciado!" in line:
            return {
                "type": "reboot",
                "needed": True
            }
        
        return {
            "type": "log",
            "message": line
        }

    async def execute_script(self):
        cmd = ["sudo", "bash", "script-manutencao.sh"]
        
        try:
            # Inicia o processo
            self.process = await asyncio.create_subprocess_exec(
                *cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            
            # Emite evento de início
            await self.socketio.emit('script_started', {
                'timestamp': datetime.now().isoformat()
            })
            
            # Processa a saída em tempo real
            while True:
                line = await self.process.stdout.readline()
                if not line:
                    break
                    
                line = line.decode().strip()
                parsed = await self.parse_output(line)
                
                # Emite eventos baseados no tipo de mensagem
                if parsed["type"] == "step":
                    await self.socketio.emit('step_update', {
                        'time': parsed["time"],
                        'step': parsed["message"]
                    })
                elif parsed["type"] in ["download", "space"]:
                    await self.socketio.emit('stats_update', parsed)
                elif parsed["type"] == "reboot":
                    await self.socketio.emit('reboot_required', parsed)
                
                await self.socketio.emit('log', {
                    'message': line,
                    'timestamp': datetime.now().isoformat()
                })
            
            # Aguarda o término do processo
            await self.process.wait()
            
            # Emite evento de conclusão
            await self.socketio.emit('script_completed', {
                'timestamp': datetime.now().isoformat(),
                'exit_code': self.process.returncode
            })
            
        except Exception as e:
            await self.socketio.emit('error', {
                'message': str(e),
                'timestamp': datetime.now().isoformat()
            })
```

4. Crie o arquivo `backend/app.py`:
```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import socketio
from script_wrapper import ScriptExecutor

app = FastAPI()
sio = socketio.AsyncServer(async_mode='asgi', cors_allowed_origins='*')
socket_app = socketio.ASGIApp(sio, app)

# Configuração CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Gerenciador de scripts
script_executor = None

@sio.event
async def connect(sid, environ):
    print(f"Client connected: {sid}")

@sio.event
async def disconnect(sid):
    print(f"Client disconnected: {sid}")

@sio.event
async def start_maintenance(sid, data):
    global script_executor
    script_executor = ScriptExecutor(sio)
    await script_executor.execute_script()

# Inicia o servidor
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(socket_app, host="0.0.0.0", port=8000)
```

## 🌐 Configuração do Frontend

1. Crie um novo projeto React com Vite:
```bash
npm create vite@latest frontend -- --template react
cd frontend
```

2. Instale as dependências:
```bash
npm install @radix-ui/react-progress @radix-ui/react-alert-dialog \
  @radix-ui/react-slot class-variance-authority clsx tailwindcss \
  lucide-react socket.io-client tailwind-merge
```

3. Configure o Tailwind CSS:
```bash
npx tailwindcss init -p
```

4. Atualize o arquivo `tailwind.config.js`:
```javascript
/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: ["class"],
  content: [
    './pages/**/*.{js,jsx}',
    './components/**/*.{js,jsx}',
    './app/**/*.{js,jsx}',
    './src/**/*.{js,jsx}',
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
```

5. Copie o componente `SystemMaintenanceUI` fornecido para `src/components/SystemMaintenanceUI.jsx`

6. Atualize o arquivo `src/App.jsx`:
```javascript
import SystemMaintenanceUI from './components/SystemMaintenanceUI'

function App() {
  return (
    <div className="min-h-screen bg-gray-100 py-8">
      <SystemMaintenanceUI />
    </div>
  )
}

export default App
```

## 🚀 Executando o Projeto

1. Inicie o backend:
```bash
cd backend
source venv/bin/activate
python app.py
```

2. Em outro terminal, inicie o frontend:
```bash
cd frontend
npm run dev
```

3. Acesse `http://localhost:5173` no navegador

## 🔒 Configuração de Permissões

1. Configure o sudo para permitir a execução do script sem senha:
```bash
sudo visudo
```

2. Adicione a linha:
```
your_username ALL=(ALL) NOPASSWD: /path/to/script-manutencao.sh
```

## 🔧 Personalizações

### Adicionando Novos Eventos

1. No `script-manutencao.sh`, adicione novas mensagens de status usando as funções existentes:
```bash
status_msg "Nova etapa"
success_msg "Operação concluída"
error_msg "Erro encontrado"
```

2. No `script_wrapper.py`, adicione novos padrões de reconhecimento:
```python
new_pattern = r"Seu padrão regex aqui"
if match := re.search(new_pattern, line):
    return {
        "type": "new_event",
        "data": match.group(1)
    }
```

3. No frontend, adicione listeners para os novos eventos:
```javascript
socket.on('new_event', (data) => {
  // Trate o novo evento
});
```

## 📝 Notas

- O sistema usa WebSocket para comunicação em tempo real
- Todas as operações são registradas em `~/ubuntu/logs/ubuntu_update.log`
- O frontend atualiza automaticamente o progresso e status
- O sistema detecta necessidade de reinicialização

## ⚠️ Resolução de Problemas

1. Se o script não executar, verifique as permissões:
```bash
sudo chmod +x script-manutencao.sh
```

2. Para problemas de conexão WebSocket:
- Verifique se as portas 8000 (backend) e 5173 (frontend) estão abertas
- Confirme se o CORS está configurado corretamente

3. Para erros de sudo:
- Verifique a configuração no arquivo sudoers
- Confirme que o caminho do script está correto

## 🤝 Contribuindo

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📜 Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.
