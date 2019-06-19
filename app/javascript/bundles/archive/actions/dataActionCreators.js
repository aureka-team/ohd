/* eslint-disable import/prefer-default-export */

import Loader from '../../../lib/loader'
import { pluralize } from  '../../../lib/utils';

import { 
    REQUEST_DATA,
    RECEIVE_DATA,
    UPDATE_DATA,
    //ADD_DATA,
    REMOVE_DATA,
    DELETE_PROCESS_MSG,
} from '../constants/archiveConstants';

//const addData = (params) => ({
    //type: ADD_DATA,
    //params: params,
    //id: id,
    //dataType: Object.keys(params)[0],
//});

const updateData = (dataType, id, data, nestedDataType, nestedId) => ({
    type: UPDATE_DATA,
    id: id,
    dataType: dataType,
    data: data,
    nestedDataType: nestedDataType,
    nestedId: nestedId,
});

const removeData = (id, dataType, nestedDataType, nestedId) => ({
    type: REMOVE_DATA,
    id: id,
    dataType: dataType,
    nestedDataType: nestedDataType,
    nestedId: nestedId,
});

const requestData = (dataType, id, nestedDataType, extraParams) => ({
    type: REQUEST_DATA,
    id: id,
    dataType: dataType,
    nestedDataType: nestedDataType,
    extraParams: extraParams,
});

const receiveData = (json) => ({
    type: RECEIVE_DATA,
    id: json.archive_id || json.id,
    data: json.data,
    dataType: json.data_type,
    nestedDataType: json.nested_data_type,
    nestedId: json.nested_id,
    extraParams: json.extra_params,
    extraId: json.extra_id,
    reloadDataType: json.reload_data_type,
    reloadId: json.reload_id,
    msg: json.msg, 
    page: json.page,
    resultPagesCount: json.result_pages_count,
});

const deleteProcessMsg = (dataType) => ({
    type: DELETE_PROCESS_MSG,
    dataType: dataType,
});

export function fetchData(dataType, id, nestedDataType, locale='de', extraParams) {
    let url = `/${locale}/${dataType}`
    if  (id)
        url += `/${id}`
    if  (nestedDataType)
        url += `/${nestedDataType}`
    if  (extraParams)
        url += `?${extraParams}`

    return dispatch => {
        dispatch(requestData(dataType, id, nestedDataType, extraParams && extraParams.replace(/[=&]/g, '_')))
        Loader.getJson(url, null, dispatch, receiveData);
    }
}

export function submitData(params, locale='de') {
    let dataType = Object.keys(params)[0]; 
    let pluralizedDataType = pluralize(dataType);

    if(params[dataType].id) {
        return dispatch => {
            Loader.put(`/${locale}/${pluralizedDataType}/${params[dataType].id}`, params, dispatch, receiveData);
        }
    } else {
        return dispatch => {
            //dispatch(addData(params));
            Loader.post(`/${locale}/${pluralizedDataType}`, params, dispatch, receiveData);
        }
    }
}

export function deleteData(dataType, id, nestedDataType, nestedId, skipRemove=false, locale='de') {
    let url = `/${locale}/${dataType}/${id}`
    if  (nestedDataType)
        url += `/${nestedDataType}/${nestedId}`

    if (skipRemove) { 
        return dispatch => {
            Loader.delete(url, dispatch, receiveData);
        }
    } else {
        return dispatch => {
            dispatch(removeData(id, dataType, nestedDataType, nestedId))
            Loader.delete(url, dispatch, receiveData);
        }
    }
}

export function returnToForm(dataType) {
    return dispatch => {
        dispatch(deleteProcessMsg(dataType))
    }
};

