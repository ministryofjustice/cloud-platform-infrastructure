from flask import jsonify, make_response
import json

class ResponseHelper(object):
  def __init__(self):
    pass
    
  def create_response(self, message, response_code):
    response = jsonify(message=message, responseCode=response_code)
    response.status_code = response_code
    return response
