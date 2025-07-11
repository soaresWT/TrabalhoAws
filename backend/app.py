from flask import Flask, request, jsonify, render_template
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime
import os
from dotenv import load_dotenv

# Carregar variáveis de ambiente
load_dotenv()

app = Flask(__name__, 
            static_folder='../frontend/static',
            template_folder='../frontend/templates')
CORS(app)

# Configuração do banco de dados
DATABASE_URL = os.getenv('DATABASE_URL', 'postgresql://postgres:password@localhost/correio_romantico')
app.config['SQLALCHEMY_DATABASE_URI'] = DATABASE_URL
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)

# Modelo de dados para as cartas
class Carta(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    remetente = db.Column(db.String(100), nullable=False)
    destinatario = db.Column(db.String(100), nullable=False)
    titulo = db.Column(db.String(200), nullable=False)
    conteudo = db.Column(db.Text, nullable=False)
    data_envio = db.Column(db.DateTime, default=datetime.utcnow)
    lida = db.Column(db.Boolean, default=False)
    
    def to_dict(self):
        return {
            'id': self.id,
            'remetente': self.remetente,
            'destinatario': self.destinatario,
            'titulo': self.titulo,
            'conteudo': self.conteudo,
            'data_envio': self.data_envio.isoformat(),
            'lida': self.lida
        }

# Criar tabelas
with app.app_context():
    db.create_all()

# Rotas da API
@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/cartas', methods=['POST'])
def enviar_carta():
    try:
        data = request.json
        
        # Validação básica
        if not all(k in data for k in ('remetente', 'destinatario', 'titulo', 'conteudo')):
            return jsonify({'error': 'Dados incompletos'}), 400
        
        nova_carta = Carta(
            remetente=data['remetente'],
            destinatario=data['destinatario'],
            titulo=data['titulo'],
            conteudo=data['conteudo']
        )
        
        db.session.add(nova_carta)
        db.session.commit()
        
        return jsonify({
            'message': 'Carta enviada com sucesso!',
            'carta': nova_carta.to_dict()
        }), 201
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/cartas/<destinatario>', methods=['GET'])
def listar_cartas(destinatario):
    try:
        cartas = Carta.query.filter_by(destinatario=destinatario).order_by(Carta.data_envio.desc()).all()
        return jsonify([carta.to_dict() for carta in cartas])
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/cartas/<int:carta_id>/ler', methods=['PUT'])
def marcar_como_lida(carta_id):
    try:
        carta = Carta.query.get_or_404(carta_id)
        carta.lida = True
        db.session.commit()
        return jsonify({'message': 'Carta marcada como lida'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({'status': 'OK', 'timestamp': datetime.utcnow().isoformat()})

if __name__ == '__main__':
    # Para desenvolvimento local
    app.run(debug=True, host='0.0.0.0', port=5000)
