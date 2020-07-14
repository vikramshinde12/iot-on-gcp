import sys
import random
from google.cloud import firestore


def upload_config_data(device_id, threshold):
    db = firestore.Client()
    doc_ref = db.collection(u'Devices').document(u'{}'.format(device_id))
    doc_ref.set({
        u'threshold': threshold
    })
    print('Master data loaded')


if __name__ == '__main__':
    argv = sys.argv[1:]
    num_of_devices = int(argv[0])
    for i in range(num_of_devices):
        upload_config_data(device_id='device'+str(i+1), threshold=random.randint(15,20))
