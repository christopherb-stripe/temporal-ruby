require 'workflows/long_workflow'

describe 'Activity cancellation' do
  let(:workflow_id) { SecureRandom.uuid }

  it 'cancels a running activity' do
    run_id = Temporal.start_workflow(LongWorkflow, options: { workflow_id: workflow_id })

    # Signal workflow after starting, allowing it to schedule the first activity
    sleep 0.5
    Temporal.signal_workflow(LongWorkflow, :CANCEL, workflow_id, run_id)

    result = Temporal.await_workflow_result(
      LongWorkflow,
      workflow_id: workflow_id,
      run_id: run_id,
    )

    expect(result).to be_a(LongRunningActivity::Canceled)
    expect(result.message).to eq('cancel activity request received')
  end

  it 'cancels a non-started activity' do
    # Workflow is started with a signal which will cancel an activity before it has started
    run_id = Temporal.start_workflow(LongWorkflow, options: {
      workflow_id: workflow_id,
      signal_name: :CANCEL
    })

    result = Temporal.await_workflow_result(
      LongWorkflow,
      workflow_id: workflow_id,
      run_id: run_id,
    )

    expect(result).to be_a(Temporal::ActivityCanceled)
    expect(result.message).to eq('ACTIVITY_ID_NOT_STARTED')
  end
end
