class RequestResult {
  bool? result;
  String? data;

  RequestResult(this.result, this.data);

  RequestResult.fromJson(Map<String, dynamic> json) {
    result = json['result'];
    data = json['data'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['result'] = result;
    data['data'] = this.data;
    return data;
  }
}