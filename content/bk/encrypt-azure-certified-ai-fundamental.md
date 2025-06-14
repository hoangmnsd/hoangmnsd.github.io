---
title: "Azure AI Fundamentals"
date: 2025-02-27T23:01:48+09:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Notes]
#tags: [Azure,Microsoft,AI]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Những notes của bản thân trong quá trình ôn thi chứng chỉ Azure AI Fundamentals"
---


1 số Lab hữu ích theo docs của MS, (chú ý nếu muốn dùng Language Studio thì phải có account work/school. Account personal ko login dc Language Studio):

Lab về Azure ML Studio (feature Automated ML) (account personal login OK). DÙng 1 dataset ( lịch sử thuê xe đạp) để train model rồi request qua endpoint: https://microsoftlearning.github.io/mslearn-ai-fundamentals/Instructions/Labs/01-machine-learning.html

Lab về Content safety studio (có thể Studio login by personal account). Sử dụng để check xem content (text, image...) có an toàn hay thù địch: https://microsoftlearning.github.io/mslearn-ai-fundamentals/Instructions/Labs/02-content-safety.html

Lab làm về Text Analytic, sử dụng Azure Language service để tạo: https://microsoftlearning.github.io/mslearn-ai-fundamentals/Instructions/Labs/06-text-analysis.html

Lab làm về Question Answering faq training, sử dụng Azure Language service để tạo.  https://microsoftlearning.github.io/mslearn-ai-fundamentals/Instructions/Labs/07-question-answering.html

Lab làm về Conversation Language Understanding (CLU) training. Các step như tạo itent/utterance/entity, rồi gán nhãn labeling data, train the model, deploy model, test endpoint : https://microsoftlearning.github.io/mslearn-ai-fundamentals/Instructions/Labs/08-conversational-language-understanding.html



# Free PT 15 câu

---
Có 6 key elements của MS AI: 
- ML, 
- Computer Vision, 
- NLP (xử lý ngôn ngữ tự nhiên), 
- Generative AI (tạo content), 
- Document intelligence, 
- Knowledge mining (tách thông tin từ dữ liệu lớn để có thể search)
Ngoài ra có Anomaly Detection (detect unusual activities)

Chú ý: Object Detection là nằm trong Computer vision.

---
MS định nghĩa các principle của Responsible AI development (Quy trình phát triển AI có trách nhiệm): 

fairness, reliability & safety, privacy & security, transparency, inclusiveness, and accountability. (công bằng, tin cậy an toàn, riêng tư bảo mật, minh bạch, toàn diện/bao quát, có trách nhiệm).

Nếu nói về possiblity và limitation thì chúng nằm trong "transparency".

- Fairness: 
Understand the purpose, scope, and intended uses of the AI system.
Work with a diverse pool of people to implement the system.
Detect and eliminate bias in datasets by examining.
Identify societal bias in machine learning algorithms.
Leverage human review and domain expertise.
Research and employ best practices.

- Inclusiveness:
Nội dung đề cập đến tầm quan trọng của tính toàn diện trong hệ thống trí tuệ nhân tạo (AI), nhấn mạnh rằng AI cần đảm bảo khả năng tiếp cận và khả năng áp dụng cho mọi người, đặc biệt là những nhóm xã hội thiếu đại diện. Các hệ thống AI phải phục vụ tốt cho nhiều nhóm học sinh khác nhau và không gây bất lợi cho ai, đặc biệt là những người khuyết tật.

- Accountability: 
Human oversight. AI systems should be monitored to ensure responsible outcomes.
Auditability. AI systems should have capabilities that allow third parties to review their operations.
Controls. AI systems should have measures in place that give you control over the system when needed.

source: https://learn.microsoft.com/en-us/training/modules/apply-responsible-ai-principles

Ngoài ra, MS còn định nghĩa các principle của MS Inclusive Design principles (thiết kế AI solution):
- Recognize exclusion (nhận diện sự loại trừ)
- Solve for one, extend to many (giải quyết 1 nhưng có thể mở rộng cho nhiều case)
- Learn from diversity (học hỏi từ sự đa dạng)

source: https://devblogs.microsoft.com/premier-developer/microsoft-inclusive-design/

---
Bạn làm việc 1 công ty bán oto, Sếp yêu cầu cung cấp thông tin cần đặt bao nhiều xe màu xanh cho quý sau. Bạn sẽ cần xây dựng ML model như nào?
- regression model dựa trên historical sale data. 

ML gồm 2 loại Supervised và UnSupervised (giám sát và không giám sát). 
```
ML
|__Supervised ML
|   |__Reggression
|   |__Classification
|       |__Binary Classification
|       |__Multiclass Classification
|__UnSupervised ML
    |__Clustering
```
source: https://learn.microsoft.com/en-us/training/modules/fundamentals-machine-learning/3-types-of-machine-learning

---
Bạn làm việc 1 công ty bán oto, Sếp yêu cầu cung cấp thông tin dự đoán mẫu xe mới có thành công ko (mẫu xe mới có các tính năng cải tiến động cơ, ghế công thái học, chống nắng). Bạn cần làm gì trong giai đoạn pre-processing data để có thể dự đoán sự thành công của mẫu xe mới?

- feature selection. Nó sẽ giúp narrow down các feature quan trọng hoặc loại bỏ các feature có vai trò ko quan trọng trong label prediction.

source: https://learn.microsoft.com/en-us/azure/architecture/data-science-process/overview

(ảnh chia theo role trong dự án) https://learn.microsoft.com/en-us/azure/architecture/data-science-process/media/overview/tdsp-tasks-by-roles.png#lightbox

Hiểu về TDSL (Team Data Science Lifecycle). Gồm 5 stages chính:
- Business understanding
- Data acquisition and understanding
- Modeling
- Deployment
- Customer acceptance

**Business understanding**: Có 2 task chính, "Define objectives" và "Identify data sources".
"Define objectives" cần: 
- Xác định `model target` (ví dụ sale forcast, hoặc khả năng order có thể là lừa đảo).
- Trả lời 5 loại câu hỏi (How much or how many?, Which category? Which group? Is this unusual? Which option should be taken?)
- Xác định metrics of success theo SMART (Specific, Measurable, Achievable, Relevant, Time-bound)

"Identify data sources" cần:
- xác định data liên quan.
- nếu data hiện tại ko liên quan thì cần tìm ở các nguồn khác.

**Data acquisition and understanding**: có 3 task chính, "Ingest data", "Explore data", "Set up a data pipeline"

**Modeling**: có 3 task chính, "Feature engineering", "Model training", "Model evaluation".

**Deployment**: Deploy the model and pipeline to a production or production-like environment for application consumption

**Customer acceptance**: 2 task chính, "System validation", "Project hand-off" (handover)

---
Bạn tạo ra 1 classification model, với 4 possible classes. Size của Confusion matrix sẽ là bao nhiêu?
- 4x4

---
Khi bạn prepare data để training, bạn phải dùng domain knowledge của bạn để chọn labels, feature, scale, và nomalize data. Trong Azure ML thì process nào bao gồm tất cả các task trên?

- featurization

source: https://learn.microsoft.com/en-us/azure/machine-learning/how-to-configure-auto-features?view=azureml-api-1

---
Azure ML Studio support các loại compute resource nào?
- Compute instances
- Compute clusters
- K8s clusters
- Attached computes

---
1 custom vision model dùng để detect các object đã train từ photos thì sẽ trả về những gì?

- bounding box
- class name (chú ý ko phải `image category`)
- probability score 

---
1 app scan 1 document nhiều trang. Trả về page info, line info, word for each line with confidence level.
API nào app đó dùng để scan document?

- Read API

Vì xử lý ảnh, scan documents là thuộc về `Computer Vision`.

- OCR chỉ là 1 synchronous service để nhận ra 1 số lượng nhỏ text trong ảnh. Nó trả về **NGAY LẬP TỨC** region of text trong image. Lines of text in regions, words for each lines.

- Read API toàn diện hơn, nhưng nó là **Asynchronous** serivce. ĐƯợc thiết kế để xử lý tác vụ nặng về text trong image/docs. Trả về thông tin chi tiết và đa dạng hơn OCR.

Tóm lại, Azure AI Vision (Computer Vision) còn cung cấp các serivce:
- OCR, Read API (đọc text)
- Image Analysis (extract object, face, adult content, auto-gen text description)
- Image Clasification (phân loại)
- Face (detect, regconise, analyze)
- Video Analysis (Spatial Analysis để phân tích hiện diện và chuyển động của ng trong video, Video Retrieval để tạo index của video để bạn có thể search với natual language)

source: https://learn.microsoft.com/en-us/azure/ai-services/computer-vision/overview

Về NLP thì Azure cung cấp các serivce:
- Text Analysis
- QnA Maker
- Language Understanding (LUIS) (Sẽ bị thay thế bằng CLU-Conversation Language Understanding từ 2025-Oct)

---
Bạn đã tạo 1 Custom Vision model dùng Azure Vision portal.
Bạn cần đưa cho developers sử dụng thì cần đưa thông tin gì?

- Project ID
- Model name
- Prediction key
- Prediction endpoint

---
trong NLP, sentiment analysis có score từ 0 đến 1. 
0 là gần mức tiêu cực, 1 là gần mức tích cực.

---
Azure AI CLU (Conversational Language Understanding) giúp bạn có thể tạo (author) 1 language model và dùng nó để dự đoán.

Giai đoạn Authoring sẽ cần define entities, intents, utterances (thực thể, ý định, câu). Rồi training model.
    - Lúc chọn entities có 4 loại: Machine-Learned, List, RegEx, and Pattern.any

Ví dụ: utterances "Turn the light on", entities là "light", intent bạn có thể define là "TurnOn"

Giai đoạn Predicting là bạn publish ra endpoint cho client consume.

---
Để tạo 1 simple web Chat Bot, bạn sẽ cần gì?

- Knowledge Base
- Bot Service

# PT1

Các mô hình tiên tiến hiện nay dựa trên kiến trúc `transformer`.
- kiến trúc mô hình `transformer` gồm encoder block và decoder block.
- Đầu vào của chúng là khối lượng lớn văn bản (từ internet). 
- Rồi được tách thách các `token`. (đây còn gọi là quá trình `tokenization`).
- `encoder block` sẽ xử lý các chuỗi token bằng kỹ thuật `attention` để xác định mối quan hệ giữa các token.
- Output của `encoder block` là tập hợp các vector (mảng nhiều giá trị), mỗi phần tử của vector đại diện cho 1 thuộc tính ngữ nghĩa của token. Các vector được gọi là `embeddings`.
- `decoder block` sẽ làm việc trên các token mới và sử dụng các `embeddings` để output ra 1 ngôn ngữ tự nhiên phù hợp.

---
tính năng chính của Azure ML:
- Automated machine learning
- Azure Machine Learning designer: a graphical interface enabling no-code development of machine learning solutions.
- Data metric visualization: analyze and optimize your experiments with visualization.
- Notebooks
- Pipelines

---
Các kỹ thuật technique trong Computer Vision:
- Image classification: clasify image dựa trên content.
- Object detection: clasify trained object trong image, có bounding box.
- Semantic segmentation: nâng cao hơn, chi tiết đến từng pixel để xác định các pixel nào thuộc về trained object.
- Image analysis: extract info từ image, mô tả image, tạo caption, sumarize.
- Face detection: ...
- OCR: detect và read text in image.

source: https://learn.microsoft.com/en-us/training/modules/get-started-ai-fundamentals/3-understand-computer-vision

---
Bạn đã tạo ra 1 AI solution để qualify điều kiện cho khách hàng vay ngân hàng. Giải pháp này đưa ra các kết quả khác nhau cho những người sống ở thành phố và khu vực nông thôn. Giải pháp này đã vi phạm principle nào?

- vi phạm tính fairness (công bằng).
- ko phải vi phạm tính Inclusiveness (bao quát). Nếu solution ko xem xét các yếu tố khác nhau của các nhóm khác nhau (ví dụ như điều kiện kinh tế, khả năng tiếp cận) thì mới là vi phạm tính Inclusiveness.

Câu hỏi như sau thì sẽ có đáp án là Inclusiveness: 
    Nếu giải pháp AI xét duyệt cho vay của ngân hàng không đảm bảo rằng tất cả các nhóm dân cư, bao gồm cả những người sống ở khu vực nông thôn và thành phố, đều có cơ hội bình đẳng để tiếp cận và hưởng lợi từ dịch vụ, thì nó vi phạm nguyên tắc nào trong các nguyên tắc AI có trách nhiệm?

---
Bạn đang build giải pháp AI, bạn cần đảm bảo rằng hệ thống hoạt động ổn định, chính xác và không gây ra rủi ro cho người dùng cũng như xã hội. Nguyên tắc AI nào bạn đang tuân theo?

- Reliability & Safety

---
Bạn đang build giải pháp AI, bạn cần đảm bảo rằng nó phản ánh luật hợp pháp, và tiêu chuẩn đạo đức. Nguyên tắc AI nào bạn đang tuân theo?

- Accountability (có trách nhiệm)

---
Bạn cần xây dựng AI model dự đoán xem các Khách hàng elite tier có thích sản phẩm ko. Thì bạn dùng mô hình nào? supervised hay unsupervised, cluster hay regression?

- classification prediciton (yes or no)

---
Các thuật toán thường sử dụng trong ML:

Regression (Hồi Quy): 
- Boosted Decision Tree Regression
- Decision Forest Regression
- Fast Forest Quantile Regression
- Linear Regression
- Neural Network Regression
- Poisson Regression

Clustering (Phân Cụm):
- K-mean

Classification (Phân Loại):
- Multiclass Boosted Decision
- Multiclass Decision Forest
- Multiclass Logistic Regression
- Multiclass Neural Network
- One-vs-All Multiclass
- One-vs-One Multiclass
- Two-Class Averaged Perceptron
- Two-Class Boosted Decision
- Two-Class Decision Forest
- Two-Class Logistic Regression
- Two-Class Neural Network
- Two-Class Support Vector Machine

---
Có nên dùng tất cả data để cho model training và model validation?

- ko. Bạn phải chia 2 phần data ra. 1 cho trainng 1 cho validation. Nếu dùng service Automated ML thì nó sẽ tự chia cho bạn.

---
4 steps typical của stage Data Transformation?

- Feature selection.(chọn lựa đặc trưng)
- Finding and removing data outliers. (tìm và loại bỏ ngoại lệ)
- Impute missing values. (điền các giá trị thiếu)
- Normalize numeric features. (chuẩn hóa đặc trưng số)

Rộng hơn về tổng quan quá trình Model Training sẽ bao gồm:

- Xác định mục tiêu và vấn đề.
- Thu thập dữ liệu (Data Ingestion / Data Collection).
- Đảm bảo dữ liệu đã được label (Provide Labeled Dataset).
- Khám phá và hiểu dữ liệu (Exploratory Data Analysis - EDA).
- Tiền xử lý dữ liệu. (Data Transformation: 4 steps bên trên).
    + Feature selection.(chọn lựa đặc trưng)
    + Finding and removing data outliers. (tìm và loại bỏ ngoại lệ)
    + Impute missing values. (điền các giá trị thiếu)
    + Normalize numeric features. (chuẩn hóa đặc trưng số)
- Tách dữ liệu (Split data 2 phần training và validate).
- Lựa chọn thuật toán (Algorithm selection).
- Model training.
- Score result.

---
Bạn cài đặt 1 visual product search app trên mobile. App sẽ tìm search product dựa trên image được capture qua camera. Cái task nào của Computer Vision service được dùng ở đây?

- Image classification

Không phải Image Analysis, vì nó giúp extract info từ ảnh ra, tag và tạo description cho ảnh.

---
Bạn đang implement giải pháp xác định khu vực bị lũ lụt cho hàng không. Cái task nào của Computer Vision service được dùng ở đây?

- Semantic segmentation. Vì nó xác định các pixel trong ảnh thuộc vùng lũ lụt hay ko?

Không phải Image Analysis, vì nó giúp extract info từ ảnh ra, tag và tạo description cho ảnh.

---
Trong Azure Computer vision có service Azure Form Recognizer service, Những key element nào service đó extract từ 1 cái hóa đơn?

Trả lời: có nhiều cái, follow cái Prebuilt models. Nhưng ko có thông tin về source of payment, hay promotion info.

source: https://learn.microsoft.com/en-us/training/modules/analyze-receipts-form-recognizer/3-azure-document-intelligence


---
AI speech service cần cung cấp ít nhất 2 khả năng:
- speech recognition (nhận diện giọng nói) dùng để phân tích giọng nói input.
- speech synthesis (tổng hợp giọng nói) dùng để tạo giọng nói output.

Trong đó, speech recognition sẽ thường dùng 2 model:
- acoustic model để chuyển đổi âm thanh thành âm vị
- language model, dự đoán chuỗi từ dựa trên âm vị

speech synthesis thì thường `tokenize` văn bản thành các từ riêng, gán với âm vị để chuyển sang âm thanh. 
Các ví dụ của speech synthesis là:
- voice menu cho hệ thống phone.
- phản hồi bằng giọng nói.
- đọc email tin nhắn thành tiếng (chế độ hand-free)
- phát thông báo tại nơi công cộng (Broadcasting announcements in public locations)

chú ý là `speaker indetification model` (nhận diện người nói) ko nằm trong topic này

source: https://learn.microsoft.com/en-us/training/modules/recognize-synthesize-speech/1-introduction


Tuy nhiên 'Azure AI Speech Service' chỉ cung cấp 2 API. 2 APi này đã bao gồm cả 2 khả năng `speech recognition và speech synthesis`:
- Speech-to-text
- Text-to-speech

source: https://learn.microsoft.com/en-us/training/modules/recognize-synthesize-speech/3-get-started-azure

---
Tính năng `Text Analytics` của 'Azure AI Language' có những feature gì?

- Named entity recognition (nhận dạng thực thể có tên)
- Entity linking (link các thực thế đến Wikipedia)
- PII (personal indetifying info) (nhận diện thông tin nhạy cảm cá nhân)
- Language detect (phát hiện ngôn ngữ)
- Sentiment analysis (phân tích cảm xúc)
- Summarization (tóm tắt)
- Key phrase extraction (trích xuất từ khóa)

source: https://learn.microsoft.com/en-us/training/modules/analyze-text-with-text-analytics-service/3-get-started-azure

---
Real-time speech translation gồm các service nào?

- Speech-to-Text -> Speech Correction -> Machine Translation -> Text-to-Speech.
- Tuy nhiên latest docs (https://learn.microsoft.com/en-us/azure/ai-services/speech-service/speech-translation) bao gồm: 
- Speech to text, speech to speech, multi-lingual speech translate, multi-target languages translate

---
Trong Generative AI, các model LLM có mục đích chính là gì?

Mặc dù có các tính năng như:
- Xác định cảm xúc, phân loại văn bản. (Determining sentiment or classifying natural language text)
- Summarize
- So sánh nhiều nguồn text để tìm sự tương đồng ngữ nghĩa (Comparing multiple text sources for semantic similarity)
- tạo băn bản tự nhiên mới (Generating new natural language).

Nhưng tính năng chính của LLM là `tạo băn bản tự nhiên mới (Generating new natural language).`

souce: https://learn.microsoft.com/en-us/training/modules/fundamentals-generative-ai/3-language%20models

---
Bạn cần train và test 1 ML model. Bạn chuẩn bị data rồi. Nhưng 1 số tính năng có thang đo (scale) khác nhau. 
Cái thứ nhất thì min,max là (0.2, 0.9). 
Cái thứ 2 thì min,max là (12, 124). 
Cái thứ 3 thì min,max là (13545, 56789). 

Bạn sẽ cần dùng method nào để giải quyết vấn đề này?

- Feature engineering (cụ thể là `Normalization`). `Feature engineering` là 1 khái niệm tổng quan, trong đó bao gồm nhiều kỹ thuật. 

    + Normalization: Chuyển các giá trị của tính năng về cùng 1 thang đo.
    + Standardization: Chuyển đổi dữ liệu sao cho có trung bình bằng 0 và độ lệch chuẩn bằng 1, khiến nó có dạng phân phối chuẩn.
    + One-Hot Encoding: Biến đổi các biến phân loại thành nhiều biến nhị phân để mô hình dễ dàng hiểu các biến phân loại mà không tạo ra thứ bậc.
    + Label Encoding: Chuyển đổi các giá trị phân loại thành các số nguyên. Thích hợp cho các biến phân loại có thứ bậc.
    + Binning: Chia dữ liệu thành các nhóm (bins) để giảm độ phức tạp và xử lý các thông tin phân phối không đồng đều.
    + Interaction Features: Tạo ra các tính năng mới bằng cách kết hợp hoặc tương tác giữa các tính năng hiện có để khám phá mối quan hệ phức tạp hơn.
    + Polynomial Features: Tạo các tính năng mới bằng cách lấy lũy thừa của các tính năng hiện có, giúp mô hình bắt kịp mối quan hệ phi tuyến tính.
    + Feature Selection: Lựa chọn các tính năng quan trọng nhất từ tập dữ liệu để loại bỏ các tính năng không cần thiết hoặc có tác động thấp đến mô hình, giúp giảm thiểu overfitting và cải thiện tốc độ.
    + Missing Value Imputation: Xử lý các giá trị thiếu bằng cách sử dụng các phương pháp như trung bình, trung vị, hoặc các mô hình khác để dự đoán giá trị thiếu.
    + Aggregation: Tạo các tính năng tổng hợp từ các tập dữ liệu khác (ví dụ: tính tổng, trung bình, min, max cho từng nhóm).
    + Temporal Features: Tạo các tính năng từ thông tin thời gian (ví dụ: năm, tháng, ngày, giờ) cho các dữ liệu có yếu tố thời gian.
    + Text Feature Extraction: Chuyển đổi dữ liệu văn bản thành các tính năng số (ví dụ: TF-IDF, Word2Vec) để sử dụng trong các mô hình học máy.

---
Bạn tạo 1 mô hình hồi quy (regression) thì trên diagram residual (phần dư). 
Nếu mô hình tốt thì giá trị residual phải được phân phối quanh mức nào?

0.
residual là khoảng cách giữa giá trị thực tế và giá trị dự đoán. 
Nếu nó sát 0 thì có nghĩa là đã dự đoán chính xác sát với thực tế.

---
Bạn cần tạo 1 pipeline để train 1 regression model dùng Azure ML Designer.
Bạn ingest data và kéo-thả data trên canvas. Rồi đến bước kéo-thả cái gì?

- Select Columns in dataset.

---
Bạn đã train 1 model xong và sẵn sàng deploy. Các step tiếp theo cần làm là gì?

- create real-time inference pipeline
- create inference cluster
- deploy inference pipeline
- test the service realtine endpoint.

source: https://learn.microsoft.com/en-us/azure/machine-learning/tutorial-designer-automobile-price-deploy?view=azureml-api-1

---
in Azure ML designer hiện đang support execute các ngôn ngữ nào?

- python, R

---
Bạn cần xác định 1 người từ file ảnh PNG 8MB thì dùng Azure Face service có khả thi ko?

- ko, hạn chế của Azure Face service là: ảnh ko được quá 6MB. chỉ các format JPEG, PNG, GIF, BMP. 
- những ảnh ko dùng được: ảnh bị cháy sáng, che 1 hoặc 2 mắt, khác kiểu tóc hoặc râu, thay đổi do tuổi tác, cảm xúc cực đoan.

source: https://learn.microsoft.com/en-us/azure/ai-services/computer-vision/concept-face-recognition

---
Azure Cognitive Face (Azure Face service) có những chức năng nào?

- Face detect and Analysis
- liveness dectection
- face identification
- verification (2 face này có cùng 1 người ko)
- find similar faces
- group faces

hạn chế:
- format: JPEG, PNG, GIF (the first frame), BMP
- size ko được vượt quá 6MB
- min face size là 36 x 36 pixel. max face size: 4096 x 4096 pixel.
- max image size 1920 x 1080.
- những ảnh ko dùng được: ảnh bị cháy sáng, che 1 hoặc 2 mắt, khác kiểu tóc hoặc râu, thay đổi do tuổi tác, cảm xúc cực đoan.

---
Bạn cần tìm key point, ý chính của văn bản thì bạn sẽ dùng service nào? có dùng LUIS được ko?

- ko, phải dùng `Text Analytics` vì nó có chức năng `Key Phrase extraction`.
LUIS thì dùng để hiểu voice & text commands, purpose classification, entity recognization.

---
bạn có 1 văn bản tiếng nước ngoài. Bạn muốn lấy Wikipedia page của 1 địa điểm trong các câu.
Bạn sẽ dùng service nào?

'Translator text' rồi 'Entity linking'

---
Bạn đang muốn training 1 language model thì bạn sẽ cần gì:

- utterances, entities, intents

---
Bạn đang phát triển 1 chatbot, cần follow quy trình của API tạo sinh có trách nhiệm, 
bạn cần có quy trình đánh giá nguy hiểm tiềm tàng.
Các step đánh giá liên quan đến potential harm bao gồm:

- Identify potential harms
    + Identify potential harms
    + Prioritize identified harms (đánh giá mức độ ưu tiên của harms)
    + test and verify các harms đã ưu tiên
    + document and share về các verified harms

- measure potential harms: đo lường, mục tiêu là tạo ra đc 1 `baseline` để định lượng các harms

- mitigate potential harms: gồm các layer:
    + model layer
    + safety system layer
    + metaprompt and grouding layer
    + User experience layer

- operate responsible generative AI

---
1 phản hồi từ GPT model sẽ như thế nào?

- A coherent and contextually relevant piece of text based on the input prompt. 
(một đoạn văn bản hợp lý và liên quan đến ngữ cảnh dựa trên lời nhắc đầu vào)

Ko chỉ bó hẹp ở hướng dẫn task, hay promgramming "Detailed instructions for a specific task, such as a recipe or programming code"

source: https://learn.microsoft.com/en-us/training/modules/introduction-to-azure-ai-studio/

# PT2

---
AI service nào sẽ cung cấp tính năng monitor 24/7 data time series để phát hiện bất thường?

- Anomaly detection

---
What is the name of the responsible AI principle that directs AI solutions design to include resistance to harmful manipulation?
(đâu là AI principle dùng để kháng cự những thao túng có hại?)

- Reliability and Safety

---
Giá trị của AUC như thế nào được coi là tốt?

- AUC = Area under curve (diện tích dưới đường cong). Nếu bằng 1 là perfect. 
thông thường AUC = 0.7 là good, AUC = 0.8 là very good.
AUC = 0.9 là excellent. 
AUC = 0.5 là random rồi.

---
các Metric để evaluate 1 mô hình AI Regression, classification, clustering?

- Metric để đánh giá model Regeression (Hồi Quy):
    + Mean Absolute Error - MAE (Sai số trung bình tuyệt đối)
    + Root Mean Squared Error - RMSE (Sai số bình phương trung bình)
    + Relative Absolute Error - RAE (Sai số tuyệt đối tương đối)
    + Relative Squared Error - RSE (Sai số bình phương tương đối)
    + Coefficient of Determination (Hệ số xác định)

- Metric để đánh giá model Classification (phân loại):
    + Accuracy (Độ chính xác) 
    + Precision (Độ chính xác dương)
    + Recall (Tỷ lệ hồi tưởng) 
    + F1 score (Điểm F1)
    + AUC (Diện tích dưới đường cong)

- Metric để đánh giá model Clustering (phân cụm):
    + Average Distance to Other Center (Khoảng cách trung bình đến trung tâm khác)
    + Average Distance to Cluster Center (Khoảng cách trung bình đến trung tâm cụm)
    + Maximal Distance to Cluster Center (Khoảng cách tối đa đến trung tâm cụm)
    + Combined Evaluation score (Đánh giá kết hợp)
    + Silhouette: Một giá trị nằm trong khoảng từ -1 đến 1, tóm tắt tỷ lệ khoảng cách giữa các điểm trong cùng một cụm và các điểm trong các cụm khác (Càng gần 1, độ tách biệt của cụm càng tốt).

---
Azure ML studio có 3 thành phần chính để Authoring model:

- Notebooks
- Automated ML
- Designer

---

Những ví dụ về app sử dụng kỹ thuật image classification:

- Detect tumor (khối u) trong ảnh X-ray (X Quang)
- search sản phẩm bằng hình ảnh (visual product search)
- nghiên cứu thảm họa (disaster investigation)

---
Bạn có 1 bức ảnh: 2 con mèo đứng trước car và bus. background có 3 cây.
Thi kỹ thuật Segmantic Segmentation sẽ identify bao nhiêu class?

- 4 (mèo, car, bus, cây)

Nó sẽ khoanh vùng làm chuẩn đến từng pixel và phân loại pixel đó thuộc class nào.


---
Trong Computer Vision, Azure Vision có 1 service là `Analyze Image API`, nó chỉ có thể trả về kết quả phân loại xem ảnh có phải là ảnh clip-art (ảnh minh họa), hay ảnh vẽ chì (line-drawing) hay ko. Nếu ảnh ko nằm trong 2 loại đó thì return 0.

Có vẻ hơi cùi.

source: https://learn.microsoft.com/en-us/azure/ai-services/computer-vision/concept-detecting-image-types

---
Nếu bạn dùng Text Analytics entity recognization API, để phân tích câu:
"After Peter met Sara at Microsoft headquarters in Paris, they visited the Eiffel tower."
Sẽ có bao nhiêu entity thuộc category Location được trả về?

3 (headquarters, Paris, Eiffel)


---
Bạn cần làm 1 telephone voice để đọc menu khi có cuộc gọi đến. Bạn cần giọng đọc phải giống human voice. Thì bạn dùng Azure TExt-to-Speech với voice là Standard thì có ok ko?

- ko, Azure TTS cung cấp 2 voice Standard và Neural. Phải chọn voice Neural thì mới giống người đọc.

---
Bạn là developer và bạn cần hiểu làm thế nào để các OpenAI model có thể apply vào new usecase. Bạn cần làm gì?

- fine-tuning model với những data mới đặc trưng cho usecase mới.

---
Giữa CLU (LUIS) và Azure Bot Service, cái nào có thể dùng để build giải pháp AI Conversational solution?

- Azure Bot service. Chứ CLU chỉ là 1 feature của NLP dùng để hiểu ngôn ngữ tự nhiên voice và text thôi.

---
Để đảm bảo tính ` Privacy and security principle` khi user dùng model trên thiết bị của họ. Model nên được run trên thiết bị user và dùng data của user. Ko nên đưa data về server. 

---
Trên Azure ML Studio, khi tạo 1 new Automated ML run, bạn có thể lựa chọn option `Explain best model`.
Cái này thể hiện priciple nào của AI solution?

- Transparency

---
Các ví dụ về sử dụng Classification model:

- Bank dự đoán khả năng trả nợ của KH
- Theo dõi dữ liệu timeseries để detect bất thường
- reading text in image (Cái này sử dụng OCR, mà OCR là 1 mô hình multi class classification model)

---
Trong ma trận nhầm lẫn nhị phân (Binary Confusion matrix).
Sẽ có 4 ô vuông 2x2 (vì là nhị phân).
vị trí tên gọi các 4 ô như sau:
```
Thực tế \ Dự đoán	Dương (Positive)	Âm (Negative)
Dương (Positive)        TP                      FN
Âm (Negative)           FP                      TN
```
- True Positive (TP): Số lượng trường hợp thực tế là Dương và được mô hình dự đoán là Dương đúng.
- True Negative (TN): Số lượng trường hợp thực tế là Âm và được mô hình dự đoán là Âm đúng.

- False Negative (FN): Số lượng trường hợp thực tế là Dương nhưng bị dự đoán sai là Âm.
- False Positive (FP): Số lượng trường hợp thực tế là Âm nhưng bị dự đoán sai là Dương.

Công thức tính Precision metric: 
```
TP/(TP+FP)
```
Công thức tính Recall metric: 
```
TP/(TP+FN)
```
Công thức tính Accuracy metric: 
```
(TP+TN)/Total number of cases
```
Công thức tính False negative rate metric: 
```
FN/(FN+TP)
```
Công thức tính Selectivity (or true negative rate) metric: 
```
TN/(TN+FP)
```

- Precision (độ chính xác): đo lường tỷ lệ trường hợp dự đoán là dương tính (positive) mà thực tế cũng dương tính. Nó chỉ ra mức độ chính xác của các dự đoán dương tính. 
    Ý nghĩa: Precision cao cho thấy rằng khi mô hình dự đoán một trường hợp là dương tính, nó có khả năng lớn chính xác. Nó quan trọng trong những trường hợp mà hậu quả của False Positive (dự đoán sai dương tính) là cao, ví dụ như trong chẩn đoán bệnh hoặc trong các tình huống đòi hỏi quyết định nghiêm túc.

- Accuracy (độ chính xác tổng thể): là tỷ lệ giữa tổng số dự đoán đúng (cả dương tính đúng và âm tính đúng) so với tổng số trường hợp. 
    Ý nghĩa: Accuracy cho thấy mức độ chính xác chung của mô hình trong việc phân loại dữ liệu. Tuy nhiên, nếu dữ liệu không cân bằng (số lượng lớp không đều), Accuracy có thể gây hiểu lầm. Ví dụ, nếu tất cả các mẫu đều thuộc vào một lớp, mô hình vẫn có thể có Accuracy cao nhưng không hữu ích trong việc phân loại chính xác các lớp khác.

- Recall (Độ nhạy, bắt nhầm hơn bỏ sót): Recall đo lường tỷ lệ trường hợp thực tế là dương tính mà được dự đoán đúng. Nó cho biết khả năng của mô hình trong việc phát hiện các trường hợp dương tính. 
    Ý nghĩa: Recall cao cho thấy rằng mô hình có khả năng tốt trong việc xác định các trường hợp dương tính. Điều này rất quan trọng trong các tình huống mà False Negative (dự đoán sai âm tính) là nhạy cảm, như trong phát hiện bệnh hoặc các loại tội phạm.

- False Negative Rate (FNR): là tỷ lệ giữa số trường hợp âm tính giả (False Negatives) so với tổng số trường hợp thực tế dương tính.
    Ý nghĩa: FNR cho biết khả năng của mô hình trong việc phát hiện các trường hợp dương tính. FNR cao cho thấy rằng mô hình không phát hiện nhiều trường hợp dương tính, điều này có thể gây ra hậu quả nghiêm trọng trong các ứng dụng như y tế (vd: phát hiện bệnh) hoặc phát hiện tội phạm. Mục tiêu thường là giảm FNR để đảm bảo rằng hầu hết các trường hợp dương tính được phát hiện.

- Selectivity (hoặc True Negative Rate): tỷ lệ giữa số trường hợp âm tính đúng (True Negatives) so với tổng số trường hợp thực tế âm tính.
    Ý nghĩa: Selectivity cho thấy khả năng của mô hình trong việc phát hiện các trường hợp âm tính. Selectivity cao cho thấy rằng mô hình chính xác trong việc xác định các trường hợp không dương tính. Mục tiêu thường là nâng cao selectivity để hạn chế các dự đoán âm tính sai (False Positive), điều này rất quan trọng trong các ứng dụng mà việc xác định âm tính chính xác là cần thiết.

Tóm tắt:
- Precision: Tập trung vào chất lượng của các dự đoán dương tính. (Thích hợp khi hậu quả của False Positive cao).
    Ví dụ: phát hiện thư rác spam. Trong bối cảnh phát hiện thư rác, việc tối ưu hóa Precision quan trọng hơn vì một False Positive có thể dẫn đến việc người dùng bỏ lỡ thông tin quan trọng. Vì vậy, trong trường hợp này, các nhà phát triển có thể điều chỉnh ngưỡng của mô hình sao cho có được Precision cao hơn, ngay cả khi điều này có thể làm giảm Recall một chút.
    **Việc dự đoán sai một ca âm tính (not spam), thực chất dương tính (spam) cũng ko vấn đề gì, vì thi thoảng ng dùng đọc 1 thư rác spam cũng ko sao. (hậu quả False Negative thấp)**

- Accuracy: Tỷ lệ tổng thể các dự đoán đúng. (Có thể không phản ánh chính xác hiệu suất mô hình nếu dữ liệu không cân bằng)

- Recall (độ nhạy, bắt nhầm hơn bỏ sót): Tập trung vào khả năng phát hiện các trường hợp dương tính. (Thích hợp khi hậu quả của False Negative cao, hậu quả False Positive thấp)
    Ví dụ: phát hiện dương tính covid19. hậu quả của việc không phát hiện một ca nhiễm (False Negative) thường cao hơn so với việc xác định sai một ca không nhiễm (False Positive). 
    **Việc dự đoán sai một ca dương tính, thực chất âm tính cũng ko vấn đề gì, vì 1 người thực chất ko bị bệnh nhưng bị xác định sai thành có bệnh thì ko vấn đề gì nhiều. (hậu quả False Postive thấp)**
    Nếu một người dương tính bị dự đoán âm tính, điều này có thể dẫn đến sự lây lan không kiểm soát của virus.

- False Negative Rate (FNR): Đo lường hiệu suất của mô hình trong việc phát hiện các trường hợp dương tính. Giảm FNR là mục tiêu trong các tình huống mà phát hiện các kết quả dương tính là quan trọng.

- Selectivity (True Negative Rate): Đo lường khả năng của mô hình trong việc xác định các trường hợp âm tính đúng. Tăng cường selectivity giúp giảm thiểu số lượng dự đoán âm tính sai (False Positive).


---
Trong Azure ML Designer, ở module `Import Data` có bao nhiêu cách để chọn Datasource?

- 2 cách: `URL via HTTP`, hoặc `Datastore`

- Khi chọn `Datastore` thì sẽ được chọn tiếp:  
    + Azure Blob storage
    + Azure file share
    + ADLS gen 1/2
    + Azure SQL, postgresql, Mysql

- Module `Import Data` này ở sau bước tạo `Dataset creation`.

- Ở bước tạo `Dataset creation` bạn mới có thể chọn: 
    + `Local files` 
    + hoặc `Open datasets`

---
Azure Face API trả về những loại biểu cảm (emotion attribute) nào?

- anger - tức giận,
- contempt - khinh thường,
- disgust - ghê tởm,
- fear - sợ hãi,
- happiness - hạnh phúc,
- neutral - trung lập,
- sadness - buồn bã,
- surprise - ngạc nhiên,

chú ý: ko có `smile`


---
Các metric để đánh giá 1 Custom Vision model performance là gì?

- Precision (độ chính xác), Recall (độ nhạy), Average Precision (độ chính xác trung bình)

source: https://learn.microsoft.com/en-us/training/modules/classify-images-custom-vision/2-azure-image-classification

---
Azure Computer Vision + Document solutions có 3 tab chính: 

- Document:
    + model pre-built cho mục đích cụ thể: invoice, receipts, health insurance card, tax form, mortage form, mariage form, credit card, contract.
    + model chung chung: OCR/Read, Layout
    + model tự train bằng data của bạn.

- Face:
    + detect face in image.

- Image:
    + detect object phổ biến.
    + gắn caption
    + caption chi tiết.
    + image search. (bạn có thể search: 1 đám cưới bạn tham dự năm ngoái)
    + OCR
    + tag extraction, image analysic

source: vào Azure Foundry -> Vision+Document tab

---
Azure dùng 1 ngôn ngữ markup riêng để control output của Speech Synthesis: SSML (not HTML)

source: https://learn.microsoft.com/en-us/azure/ai-services/speech-service/speech-synthesis-markup?tabs=csharp

---
Azure AI Translator API cung cấp 2 option để fine-tuning (tinh chỉnh) kết quả trả về:
- Profanity filtering (lọc từ thô)
- Selective translation (dịch có chọn lọc) (ví dụ bạn đánh tag để ko dịch các tag code , brand name, location name)

- Tuy nhiên mình xem docs ko thấy selective translation đâu: https://learn.microsoft.com/en-us/azure/ai-services/translator/reference/v3-0-translate

https://learn.microsoft.com/en-us/training/modules/translate-text-with-translation-service/2-get-started-azure

---
2 usecase scenarios của Azure Speech to text API là gì?
- conversational (hội thoại)
- dictation (đánh máy)

source: https://learn.microsoft.com/en-us/training/modules/recognize-synthesize-speech/3-get-started-azure

---
Codex model của OpenAI là gì?

- 1 model dùng để generate code completion dựa trên input.

---
Bạn đã tạo Azure Bot. Giờ muốn embbed bot vào vào website thì cần gì?

- Obtain secret
- generate token base on secret

---
Nếu bạn train 1 ML model bằng 1 dataset ko có label. Nghĩa là bạn đang dùng model type nào?

- Clustering (phân cụm) (thuộc loại Unsupervised) vì chỉ Clustering mới dùng các dataset ko labeled.

---
Nếu bạn đang dùng thuật toán `Two-class logistic regression algorithm` để train model thì model đó thuộc type nào?

- Classification model (vì cứ nhiều class là dùng cho Classification)

thuật toán `Two-class logistic regression` là 1 phần của thuật toán `Multiclass Logistic Regression`


---
Hạn chế của Object detection model trong Computer Vision?

- ko detect dc object nhỏ hơn 5% image
- ko detect dc những object nếu xếp quá gần nhau (như 1 chồng đĩa)
- ko detect sự khác nhau về brand name giữa các sản phẩm khác brand (ví dụ các loại nc ngọt khác nhau trên kệ)


---
Azure Face API có thể trả về thông tin về face có makeup hay ko ?

- có eyeMakeup, lipMakeup
- ngoài ra còn có các loại emtions, tuổi, giới tính, đeo kính ko?, râu trên mặt (moustache, beard)

---
Nếu bạn dùng Text Analytics Key Phrases API thì sẽ lấy đc bao nhiêu key trong câu này:

"Peter met Sara at Microsoft headquarters in Paris."

- 4 (Peter, Sara, Microsoft headquarters, Paris)

Từ "met" không được coi là một key phrase trong ngữ cảnh phân tích ngữ nghĩa vì nó là một động từ mô tả hành động mà không mang lại thông tin cụ thể về đối tượng, địa điểm hay khái niệm chính. Key phrases thường bao gồm danh từ, danh từ cụm hoặc thực thể có ý nghĩa cụ thể, có thể nhận diện và có giá trị thông tin cao hơn.

---

# Final Test

---
QnA Maker service có support Multi language ko?

- ko. Bạn tạo QnA Maker resource: A, rồi bạn tạo knowledge base đầu tiên, (ở đây bạn define language sẽ sử dụng) và bạn sẽ ko thể thay đổi sau đó. 
kể cả khi bạn tạo nhiều knowledge base khác thì lanaguage cho QnA Maker A cũng ko thay đổi về sau.



---
(Câu này outdate thì phải? vào xem ko thấy template ở đâu)
Bạn cần tạo Language Understanding WebApp bot có 2 template:

- Echo bot: template để simple echo user message.
- Basic bot: template này support LU.

---
2 models mà Azure Bot Framework support để integrate với Customer support service?

- Bot as agent (user nói chuyện với agent hub, bot ngang hàng với các human agent khác, đều connect vào `agent hub`, nếu bot cần phối hợp với human agent thì sẽ escalate cho human agent)
- Bot as proxy (user nói chuyện với Bot trước, rồi bot sẽ quyết định xem có cần human agent phối hợp ko. Nếu có thì bot sẽ request đến `agent hub`)


# PT 10 câu theo từng domain

---
primary feature của github copilot?

- Code suggestion và auto completion (chú ý ko phải là generate ra code base on input)

---
OpenAI Dall-E ko có khả năng generate ra 3D model từ text đâu.

---
Counterfit là 1 opensource project giúp tăng cường bảo mật bằng cách nào?

- mô phỏng stimulate các cuộc tấn công mạng chống lại AI. Nó cung cập các CLI tool để test độ resillence của AI model.

---
Model AI nào có khả năng tốt về chuyển text thành vivid images (hình ảnh sống động)

- Dall E

---
Các foundation models chủ yếu được dùng làm gì trong generative AI?

- fine-tuning for specific language understanding task
(tinh chỉnh cho các nhiệm vụ ngôn ngữ cụ thể)

---



# Bài Practice test của MS

https://learn.microsoft.com/en-us/credentials/certifications/azure-ai-fundamentals/practice/assessment?assessment-type=practice&assessmentId=26&practice-assessment-type=certification

---
Cái gì được dùng để "used to identify constraints and styles for the responses of a generative AI model."

- System messages

---
1 generative AI model có thể tạo ảnh, chỉnh sửa ảnh, tạo các variation khác nhau từ 1 ảnh cho trước.

---
Bạn cần xác định các giá trị số đại diện cho xác suất con người phát triển bệnh tiểu đường dựa trên độ tuổi và tỷ lệ phần trăm mỡ cơ thể. Bạn nên sử dụng loại mô hình máy học nào? `linear regression` hay `logistic regression`? 

- dùng hồi quy logistic (`logistic regression`). Vì bạn đang cố gắng xác định xác suất của 1 kết quả nhị phân (có hoặc ko phát triển bệnh).
Hồi quy tuyến tính (`linear regression`) chỉ phù hợp khi bạn dự đoán 1 giá trị liên tục.

- vì là sự kiện nhị phân (có hoặc ko phát triển bệnh) nên cũng có thể dùng `classification`. nhưng vì bạn cần xác suất nên dùng `logistic regression` hợp lý hơn.

---
Khi bạn cần xác định các giá trị số đại diện cho xác suất con người phát triển bệnh tiểu đường dựa trên độ tuổi và tỷ lệ phần trăm mỡ cơ thể. Có bao nhiêu features và bao nhiêu label mà model của bạn cần?

- 2 features (age and body fat pct), 1 label (có hay ko phát triển bệnh)

---
Which type machine learning algorithm predicts a numeric label associated with an item based on that item’s features?

- regression (hồi quy) chứ ko phải classificaiton. vì đang muốn predict 1 giá trị mà. ko phải muốn phân loại.

---
Which assumption of the multiple linear regression model should be satisfied to avoid misleading predictions?

- Features are independent of each other.

---
Một công ty triển khai một chiến dịch tiếp thị trực tuyến trên các nền tảng truyền thông xã hội để ra mắt một sản phẩm mới. Công ty muốn sử dụng machine learning để đo lường cảm xúc của người dùng trên nền tảng Twitter, những người đã đăng bài phản hồi về chiến dịch. Loại machine learning này là gì?

- phân loại (classification)

---
1 công ty dùng ML để dự đoán price của house dựa trên house attributes? đâu là label? đâu là features?

- Label là: price of house
- Features là: age of house, floor size, bedroom number...

---
You need to use Azure Machine Learning to train a regression model.
What should you create in Machine Learning studio?

- trong Azure ML Studio bạn sẽ tạo cac job, còn workspace là thứ bạn cần tạo trước khi tạo Azure ML studio.

---
1 số kỹ thuật xử lý NLP:
- stemming: chuẩn hóa các từ trước khi đếm chúng
- frequency analysis: đếm số lần một từ xuất hiện trong một văn bản
- N-grams: mở rộng phân tích tần suất để bao gồm các cụm từ nhiều thành phần.
- Vectorization: nắm bắt các mối quan hệ ngữ nghĩa


Kỹ thuật xử lý NLP nào chuẩn hóa các từ trước khi (count) đếm chúng?:

- stemming (chuẩn hóa dạng gốc).

Kỹ thuật xử lý NLP nào gán giá trị cho các từ như "cây" và "hoa", để chúng được coi là gần nhau hơn so với một từ như "máy bay"?

- Vectorization: nắm bắt các mối quan hệ ngữ nghĩa

---
Kỹ thuật trí tuệ nhân tạo (AI) nào là nền tảng/foundation cho các giải pháp morden image classification (phân loại hình ảnh hiện đại)?
phân đoạn ngữ nghĩa (semantic segmentation).
học sâu (deep learning).
hồi quy tuyến tính (linear regression).
hồi quy tuyến tính bội (multiple linear regression).

- Câu trả lời là: học sâu (deep learning). Học sâu là phương pháp chủ yếu được sử dụng trong giải pháp phân loại hình ảnh hiện đại, nhờ khả năng tự động rút trích đặc trưng từ dữ liệu hình ảnh một cách hiệu quả.

---
Trong Computer Vision service, cái nào cho output mà có bounding box?

- object detection cung cấp bounding box tọa độ của các đối tượng trong ảnh.
- semantic segmentation: cung cấp khả năng phân loại đến từng pixel.
- image classification: phân loại dựa trên content của ảnh.
- image analysis: trích xuất thông tin từ ảnh để labeling hoặc tagging hoặc chú thích/caption.

---
tracking livestock in a field. Theo dõi gia súc trên cánh đồng.

---
Azure AI Vision sẽ cung cấp các mô hình được đào tạo sẵn. Thế nên bạn sẽ không có lựa chọn: choosing model, training model, evaluating model.


# 1 số câu hỏi mình gặp phải khi đi thi thực tế

Model lựa đúng 70 quả cam trong số 100 ảnh có cam thì 70% là độ recall hay precision..

Bạn cần extract thông tin từ scanned image về receipt thì cần dùng sv gì, ai serch, az imersive reader, document intelligent?

Bạn cần predict số dặm per galon xăng dựa trên loại xe, loại xăng .. thì dùng model type regression, classification?

Data input value cho model gọi là feature, hay label?

Bạn có 1000 image, cần extract info từ đó ra dùng svc gì, image classification, ocr?

Bạn có 1000 image về widget cần xác định location của mỗi widget trong mỗi ảnh đó thì dùng svc gì, az vision spatial? 

Model dc dùng bởi những ng có audio, visual impairment thì cần đáp ứng principle nào? Inclusiveness?

