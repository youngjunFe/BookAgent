class EBook {
  final String id;
  final String title;
  final String author;
  final String content;
  final String? coverImageUrl;
  final DateTime addedAt;
  final DateTime? lastReadAt;
  final int totalPages;
  final int currentPage;
  final double progress; // 0.0 to 1.0
  final bool isCompleted; // 완독 여부
  final List<String> chapters;

  EBook({
    required this.id,
    required this.title,
    required this.author,
    required this.content,
    this.coverImageUrl,
    required this.addedAt,
    this.lastReadAt,
    required this.totalPages,
    this.currentPage = 0,
    this.progress = 0.0,
    this.isCompleted = false,
    this.chapters = const [],
  });

  // 페이지별로 콘텐츠를 나누기 (간단한 구현)
  List<String> get pages {
    const wordsPerPage = 300; // 한 페이지당 단어 수
    final words = content.split(' ');
    final List<String> pageList = [];
    
    for (int i = 0; i < words.length; i += wordsPerPage) {
      final endIndex = (i + wordsPerPage < words.length) ? i + wordsPerPage : words.length;
      pageList.add(words.sublist(i, endIndex).join(' '));
    }
    
    return pageList.isEmpty ? [''] : pageList;
  }

  EBook copyWith({
    String? id,
    String? title,
    String? author,
    String? content,
    String? coverImageUrl,
    DateTime? addedAt,
    DateTime? lastReadAt,
    int? totalPages,
    int? currentPage,
    double? progress,
    bool? isCompleted,
    List<String>? chapters,
  }) {
    return EBook(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      content: content ?? this.content,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      addedAt: addedAt ?? this.addedAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      chapters: chapters ?? this.chapters,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'content': content,
      'coverImageUrl': coverImageUrl,
      'addedAt': addedAt.toIso8601String(),
      'lastReadAt': lastReadAt?.toIso8601String(),
      'totalPages': totalPages,
      'currentPage': currentPage,
      'progress': progress,
      'chapters': chapters,
    };
  }

  factory EBook.fromJson(Map<String, dynamic> json) {
    return EBook(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      content: json['content'],
      coverImageUrl: json['coverImageUrl'],
      addedAt: DateTime.parse(json['addedAt']),
      lastReadAt: json['lastReadAt'] != null ? DateTime.parse(json['lastReadAt']) : null,
      totalPages: json['totalPages'],
      currentPage: json['currentPage'] ?? 0,
      progress: json['progress']?.toDouble() ?? 0.0,
      chapters: List<String>.from(json['chapters'] ?? []),
    );
  }

  // 샘플 책들
  static List<EBook> get sampleBooks {
    return [
      EBook(
        id: '1',
        title: '어린 왕자',
        author: '앙투안 드 생텍쥐페리',
        content: _sampleContent1,
        addedAt: DateTime.now().subtract(const Duration(days: 10)),
        lastReadAt: DateTime.now().subtract(const Duration(days: 2)),
        totalPages: 12,
        currentPage: 3,
        progress: 0.25,
        chapters: ['1장: 모자', '2장: 어린 왕자를 만나다', '3장: 별에서 온 아이'],
      ),
      EBook(
        id: '2',
        title: '데미안',
        author: '헤르만 헤세',
        content: _sampleContent2,
        addedAt: DateTime.now().subtract(const Duration(days: 5)),
        totalPages: 20,
        currentPage: 0,
        progress: 0.0,
        chapters: ['1장: 두 개의 세계', '2장: 카인', '3장: 도둑'],
      ),
      EBook(
        id: '3',
        title: '1984',
        author: '조지 오웰',
        content: _sampleContent3,
        addedAt: DateTime.now().subtract(const Duration(days: 1)),
        lastReadAt: DateTime.now().subtract(const Duration(hours: 3)),
        totalPages: 25,
        currentPage: 15,
        progress: 0.6,
        chapters: ['1부: 빅 브라더', '2부: 골드스타인의 책', '3부: 101호실'],
      ),
    ];
  }

  static const String _sampleContent1 = '''
어른들은 숫자를 좋아한다. 새로 사귄 친구에 대해 이야기할 때, 어른들은 정작 중요한 것은 묻지 않는다. "그 아이의 목소리는 어떻게 들리지?", "그 아이가 좋아하는 게임은 뭐지?", "그 아이는 나비를 모으나?" 같은 질문은 절대 하지 않는다. 대신 "그 아이는 몇 살이지?", "형제는 몇 명이나 되지?", "몸무게는 얼마나 나가지?", "그 아이 아버지는 얼마나 벌지?" 하고 묻는다. 그래야만 그 아이에 대해 안다고 생각한다.

만약 어른들에게 "창문에 제라늄이 피어 있고, 지붕에 비둘기들이 앉아 있는 분홍색 벽돌집을 봤어요"라고 말한다면, 그들은 그 집이 어떤 집인지 상상하지 못할 것이다. "10만 프랑짜리 집을 봤어요"라고 말해야 "아, 정말 멋진 집이겠구나!"라고 감탄한다.

마찬가지로 "어린 왕자가 존재했다는 증거는 그가 정말 사랑스러웠고, 웃었고, 양 한 마리를 원했다는 것입니다. 양을 원한다는 것은 그가 존재한다는 증거입니다"라고 말한다면, 어른들은 어깨를 으쓱할 것이다. 그리고 당신을 아이 취급할 것이다!

하지만 "그는 소행성 B-612에서 왔습니다"라고 말하면, 금방 납득하고 더 이상 질문으로 괴롭히지 않을 것이다. 어른들이란 그런 존재다. 어른들을 탓해서는 안 된다. 아이들은 어른들에게 관대해야 한다.

물론 우리들처럼 인생이 무엇인지 아는 사람들은 숫자 따위는 우습게 생각한다! 나는 이 이야기를 옛날 옛적에 일어난 일처럼 시작하고 싶었다.

"옛날 옛적에 어린 왕자가 살았는데, 그는 자기보다 조금 큰 별에 살았고, 친구가 필요했습니다..." 인생이 무엇인지 아는 사람들에게는 이렇게 말하는 것이 훨씬 진실에 가깝게 들렸을 것이다.

나는 내 이야기가 가벼운 마음으로 읽히는 것을 원하지 않는다. 이 추억들을 이야기하는 것이 나에게는 너무나 슬픈 일이기 때문이다. 내 친구는 양과 함께 벌써 6년 전에 떠나갔다. 내가 여기서 그를 그리려고 하는 것은 그를 잊지 않기 위해서다. 친구를 잊는다는 것은 슬픈 일이다. 모든 사람이 친구를 가져 본 것은 아니다.

그리고 나는 숫자만 좋아하는 어른이 될까 봐 두렵다. 그래서 색연필과 연필을 샀다. 내 나이에 그림을 다시 시작한다는 것은 쉬운 일이 아니다! 6살 때 보아뱀 그림 말고는 그려 본 적이 없는데 말이다. 물론 나는 가능한 한 실물과 닮게 그리려고 노력할 것이다. 하지만 성공할 자신은 없다.

한 그림은 괜찮고 다른 그림은 전혀 닮지 않는다. 키에서도 조금 실수를 한다. 여기서는 어린 왕자가 너무 크고 저기서는 너무 작다. 옷 색깔도 망설여진다. 그래서 이렇게 저렇게 더듬거리며 그려 본다. 아마 더 중요한 세부사항에서는 틀릴 수도 있을 것이다.

하지만 이것은 용서해 주기 바란다. 내 친구는 설명을 해 준 적이 없다. 아마 그는 나를 자기와 같다고 생각했을 것이다. 하지만 불행하게도 나는 상자 속의 양을 볼 수 있는 능력이 없다. 나는 아마 어른들과 조금 비슷한 것 같다. 나이를 먹어서 그런 것 같다.
''';

  static const String _sampleContent2 = '''
내 인생 이야기를 하려는 것이 아니다. 다른 사람들의 인생 이야기를 하려는 것도 아니다. 그런 것들은 오직 시인들만이 할 수 있는 일이다. 내가 하려는 것은 한 인간 속에서 자연이 어떻게 각성해 가려고 노력하는가 하는 이야기이다. 그것은 새로운 길이며 탄생의 길이다.

모든 사람의 인생은 이런 길이다. 어떤 사람은 무의식 속에서, 어떤 사람은 의식적으로 이 길을 간다. 모든 사람은 어떤 목적지를 향해 던져졌지만, 그 던져진 장소로부터 다시 뛰어오를 수 있다. 우리는 모두 자연으로부터 솟아나왔지만, 각자는 자신만의 도전을 맞고 자신만의 목표를 지향한다.

우리는 서로를 이해할 수 있다. 하지만 각자를 해석할 수 있는 것은 자기 자신뿐이다.

내가 이야기하려는 것은 1891년경부터 시작된다. 당시 내가 열 살이었을 때의 일들이다.

나는 목사의 아들로서 조용한 소도시에서 자랐다. 우리 집 옆에는 더 나이 많은 소녀들이 사는 집이 있었다. 나는 그 집의 막내딸 마리아와 함께 놀았다. 마리아는 나보다 두 살 연상이었다.

어떻게 모든 것이 시작되었는지 기억나지 않는다. 다만 그때의 기분만은 생생히 기억한다. 우리는 둘 다 열 살이나 열한 살 정도였다. 마리아는 나에게 어떤 새로운 게임을 가르쳐 주겠다고 했다. 그녀는 나를 헛간으로 데려갔고, 거기서 나에게 모든 사람들이 어른이 되면 하는 일을 가르쳐 주겠다고 말했다.

이 첫 번째 유혹이 내게 죄의식을 심어 주었다. 나는 그것이 금지된 것이며 비밀로 해야 한다는 것을 본능적으로 알았다. 하지만 그것은 또한 즐거운 일이기도 했다. 나는 그것을 부끄러워했지만 동시에 갈망하기도 했다.

이때부터 내 안에는 두 개의 세계가 생겨났다. 하나는 우리 집이 대표하는 합법적이고 명정한 세계였다. 거기서는 아침 기도와 성경읽기, 깨끗함과 정결함이 지배했다. 거기서는 직선과 의무의 길이 있었다.

다른 하나는 전혀 다른 세계였다. 그곳에는 하녀들과 도제들이 살았고, 귀신 이야기와 스캔들이 있었다. 거기서는 온갖 종류의 매혹적이고 무서운 것들, 수수께끼 같은 것들이 소용돌이쳤다. 도살장과 감옥, 술주정뱅이들과 고함치는 여자들, 새끼 낳는 소들, 쓰러져 죽는 말들, 강도와 살인자들에 대한 이야기가 있었다.

두 세계는 모두 정당했고, 둘 다 진짜였다. 하지만 그들은 서로 모순되었다.
''';

  static const String _sampleContent3 = '''
4월의 밝고 차가운 날이었고, 시계가 열세 시를 알리고 있었다. 윈스턴 스미스는 목을 움츠리고 매서운 바람을 피하려 하면서 빅토리 맨션의 유리문 안으로 재빠르게 미끄러져 들어갔다. 그러나 바람을 차단하기에는 역부족이었다. 바람은 그를 따라 들어와 모래 먼지를 날렸다.

복도에서는 삶은 양배추와 낡은 러그 냄새가 났다. 한쪽 끝에는 화려한 색깔의 포스터가 벽에 붙어 있었는데, 실내에 걸기에는 너무 컸다. 그것은 거대한 얼굴을 그린 것이었다. 45세 정도 되는 남자의 얼굴로, 짙고 검은 콧수염이 있었고, 거칠지만 잘생긴 얼굴이었다. 윈스턴은 계단으로 향했다. 엘리베이터를 시도해 보는 것은 무의미했다. 가장 좋은 때조차도 거의 작동하지 않았고, 지금은 낮 시간에 전기가 차단되어 있었다. 그것은 증오주간을 대비한 절약의 일환이었다.

윈스턴의 아파트는 7층에 있었고, 그는 39세에 우다리에 정맥류가 있어서 천천히 올라갔다. 각 층마다 계단참에서 엘리베이터 샤프트 맞은편 벽에서 거대한 얼굴이 포스터에서 그를 내려다보고 있었다. 그것은 시선을 따라다니도록 만들어진 그림들 중 하나였다. "빅 브라더가 당신을 지켜보고 있다"는 캡션이 밑에 적혀 있었다.

아파트 안에서는 풍부하고 목이 메는 목소리가 철강 생산에 관한 수치들의 목록을 읽어 내고 있었다. 그 목소리는 오른쪽 벽에 있는 직사각형 금속판에서 나오고 있었는데, 그것은 흐릿한 거울처럼 보였다. 윈스턴이 스위치를 돌리자 목소리는 다소 줄어들었지만 단어들은 여전히 구별되었다. 그 기구(텔레스크린이라고 불렸다)는 줄일 수는 있었지만 완전히 끌 수는 없었다.

윈스턴은 창가로 갔다. 그는 작고 연약한 체격이었는데, 그의 연약함은 파란색 작업복(그것이 당의 제복이었다)에 의해 더욱 부각되었다. 그의 머리카락은 누런빛이었고, 얼굴은 자연히 붉었으며, 거친 비누와 무딘 면도날과 방금 끝난 겨울의 추위로 인해 피부가 거칠었다.

밖에서는, 닫힌 창문을 통해서도 세상이 춥게 보였다. 거리에서는 작은 소용돌이치는 바람이 먼지와 찢어진 종이를 나선형으로 올렸고, 태양이 밝게 비추고 하늘이 강렬한 파란색이었음에도 불구하고 색깔 있는 것이라고는 여기저기 붙어 있는 포스터들밖에 없는 것 같았다.

검은 콧수염 얼굴이 모든 지배적인 모서리에서 내려다보고 있었다. 바로 맞은편 집 정면에 하나가 있었다. "빅 브라더가 당신을 지켜보고 있다"고 캡션이 말했고, 어두운 눈이 윈스턴의 눈을 똑바로 바라보았다.
''';
}
