import cv2
import numpy as np
from flask import Flask, request, jsonify
import imutils
from roboflow import Roboflow

RF_API_KEY = "SHHH!!!"
RF_WORKSPACE_ID = "gabaritos-h9iie"

# Modelo 1: Detetor de Gabarito
DETECTOR_PROJECT_NAME = "detc-gabarito"
DETECTOR_VERSION = 1

# Modelo 2: Classificador de Bolhas
CLASSIFIER_PROJECT_NAME = "classificador-de-alternativas"
CLASSIFIER_VERSION = 1

rf = Roboflow(api_key=RF_API_KEY)
workspace = rf.workspace(RF_WORKSPACE_ID)

# Carrega o modelo detetor
detector_project = workspace.project(DETECTOR_PROJECT_NAME)
detector_version = detector_project.version(DETECTOR_VERSION)
detector_model = detector_version.model

# Carrega o modelo classificador
classifier_project = workspace.project(CLASSIFIER_PROJECT_NAME)
classifier_version = classifier_project.version(CLASSIFIER_VERSION)
classificador_model = classifier_version.model

app = Flask(__name__)

# As funções auxiliares (detectar_folha, order_points, four_point_transform) permanecem as mesmas
def detectar_folha_com_modelo(imagem_completa):
    cv2.imwrite("temp_image.jpg", imagem_completa)
    predictions = detector_model.predict("temp_image.jpg", confidence=40, overlap=30).json()
    if predictions['predictions']:
        box = predictions['predictions'][0]
        x_center, y_center, width, height = box['x'], box['y'], box['width'], box['height']
        x_min = int(x_center - width / 2); y_min = int(y_center - height / 2)
        x_max = int(x_center + width / 2); y_max = int(y_center + height / 2)
        return np.array([[x_min, y_min], [x_max, y_min], [x_max, y_max], [x_min, y_max]], dtype="float32")
    return None

def classificar_bolha_com_matematica(imagem_bolha):
    gray = cv2.cvtColor(imagem_bolha, cv2.COLOR_BGR2GRAY)
    thresh = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY_INV | cv2.THRESH_OTSU)[1]
    return cv2.countNonZero(thresh)

def classificar_bolha_com_ia(imagem_bolha):
    cv2.imwrite("temp_bolha_verificacao.jpg", imagem_bolha)
    prediction = classificador_model.predict("temp_bolha_verificacao.jpg").json()
    if 'predictions' in prediction and prediction['predictions']:
        return prediction['predictions'][0]['top']
    return "vazia"

@app.route('/analisar_prova', methods=['POST'])
def analisar_prova():
    if 'imagem' not in request.files: return jsonify({'erro': 'Nenhuma imagem enviada'}), 400
    file = request.files['imagem']; npimg = np.fromfile(file, np.uint8)
    img = cv2.imdecode(npimg, cv2.IMREAD_COLOR)

    print("Usando a API para detectar o gabarito...")
    pontos_gabarito = detectar_folha_com_modelo(img)
    if pontos_gabarito is None: return jsonify({'erro': 'Não foi possível detectar a folha.'}), 400
    
    folha_corrigida = four_point_transform(img, pontos_gabarito)

    print("Detectando as bolhas de alternativas...")
    thresh_para_contornos = cv2.threshold(cv2.cvtColor(folha_corrigida, cv2.COLOR_BGR2GRAY), 0, 255, cv2.THRESH_BINARY_INV | cv2.THRESH_OTSU)[1]
    cnts = cv2.findContours(thresh_para_contornos.copy(), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    cnts = imutils.grab_contours(cnts)
    bolhas_cnts = [c for c in cnts if cv2.boundingRect(c)[2] >= 20 and cv2.boundingRect(c)[3] >= 20 and 0.8 <= cv2.boundingRect(c)[2] / float(cv2.boundingRect(c)[3]) <= 1.2]
    if not bolhas_cnts or len(bolhas_cnts) % 5 != 0: return jsonify({'erro': 'Número de bolhas detectado é inválido.'}), 400

    bolhas_cnts = sorted(bolhas_cnts, key=lambda c: cv2.boundingRect(c)[1])
    respostas_mapeadas = {}
    alternativas = ['A', 'B', 'C', 'D', 'E']
    
    print("Analisando respostas com o método Híbrido Final...")
    for i in np.arange(0, len(bolhas_cnts), 5):
        linha_atual_cnts = sorted(bolhas_cnts[i:i+5], key=lambda c: cv2.boundingRect(c)[0])
        
        # 1. Filtro rápido com matemática para encontrar o candidato mais provável
        densidades = [classificar_bolha_com_matematica(folha_corrigida[cv2.boundingRect(c)[1]:cv2.boundingRect(c)[1]+cv2.boundingRect(c)[3], cv2.boundingRect(c)[0]:cv2.boundingRect(c)[0]+cv2.boundingRect(c)[2]]) for c in linha_atual_cnts]
        
        # 2. A matemática elege o "campeão" da linha (o mais escuro)
        idx_candidato = np.argmax(densidades)
        
        # 3. Pega a imagem desse candidato
        candidato_cnt = linha_atual_cnts[idx_candidato]
        (x, y, w, h) = cv2.boundingRect(candidato_cnt)
        bolha_candidata_img = folha_corrigida[y:y+h, x:x+w]
        
        # 4. A IA dá o veredito final, sem limiares fixos.
        status_ia = classificar_bolha_com_ia(bolha_candidata_img)
        
        escolha_aluno = "N/A"
        if status_ia == "marcada":
            escolha_aluno = alternativas[idx_candidato]

        numero_questao = str((i // 5) + 1)
        respostas_mapeadas[numero_questao] = escolha_aluno

    print("Análise concluída com sucesso!")
    return jsonify(respostas_mapeadas)


def order_points(pts):
	rect = np.zeros((4, 2), dtype = "float32"); s = pts.sum(axis = 1)
	rect[0] = pts[np.argmin(s)]; rect[2] = pts[np.argmax(s)]
	diff = np.diff(pts, axis = 1)
	rect[1] = pts[np.argmin(diff)]; rect[3] = pts[np.argmax(diff)]
	return rect

def four_point_transform(image, pts):
	rect = order_points(pts); (tl, tr, br, bl) = rect
	widthA = np.sqrt(((br[0] - bl[0]) ** 2) + ((br[1] - bl[1]) ** 2))
	widthB = np.sqrt(((tr[0] - tl[0]) ** 2) + ((tr[1] - tl[1]) ** 2))
	maxWidth = max(int(widthA), int(widthB))
	heightA = np.sqrt(((tr[0] - br[0]) ** 2) + ((tr[1] - br[1]) ** 2))
	heightB = np.sqrt(((tl[0] - bl[0]) ** 2) + ((tl[1] - bl[1]) ** 2))
	maxHeight = max(int(heightA), int(heightB))
	dst = np.array([[0, 0], [maxWidth - 1, 0], [maxWidth - 1, maxHeight - 1], [0, maxHeight - 1]], dtype = "float32")
	M = cv2.getPerspectiveTransform(rect, dst)
	warped = cv2.warpPerspective(image, M, (maxWidth, maxHeight))
	return warped

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
